#!/usr/bin/env python3
"""Email aggregated WhatsApp campaign failures; never send/retry campaigns."""
import argparse
from datetime import datetime, timezone
from email.message import EmailMessage
import json
import os
from pathlib import Path
import subprocess
import sys

from workflow_failure_alerts import deliver_email, exclusive_lock, read_config, save_state


def campaign_failures(config, state):
    since = datetime.fromisoformat(state['since']).astimezone(timezone.utc).isoformat()
    sql = f'''SELECT row_to_json(alert) FROM (
      SELECT c.id, c.account_id, c.campaign_status,
        count(r.id) FILTER (WHERE r.state='failed') AS failed,
        count(r.id) FILTER (WHERE r.state='unknown') AS unknown
      FROM campaigns c JOIN inboxes i ON i.id=c.inbox_id
      LEFT JOIN campaign_recipients r ON r.campaign_id=c.id
      WHERE i.channel_type='Channel::Whatsapp'
      GROUP BY c.id,c.account_id,c.campaign_status,c.updated_at
      HAVING (c.campaign_status IN (5,6) OR count(r.id) FILTER (WHERE r.state IN ('failed','unknown'))>0)
        AND GREATEST(c.updated_at,COALESCE(max(r.updated_at),c.updated_at)) >= '{since}'::timestamptz
      ORDER BY c.id
    ) alert;'''
    if config.get('INBOX_DATABASE_CONTAINER'):
        command = ['docker', 'exec', '-i', config['INBOX_DATABASE_CONTAINER'], 'psql', '-X',
                   '-v', 'ON_ERROR_STOP=1', '-U', config['INBOX_DATABASE_USER'],
                   '-d', config['INBOX_DATABASE_NAME'], '-At']
        environment = None
    else:
        command = ['psql', '-X', '-v', 'ON_ERROR_STOP=1', '-At']
        environment = dict(os.environ, PGDATABASE=config['VOLITEX_DATABASE_URL'])
    result = subprocess.run(command, input=sql, text=True, capture_output=True, env=environment, timeout=30)
    if result.returncode:
        raise RuntimeError('Campaign metadata query failed')
    return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]


def notification_key(campaign):
    return ':'.join(str(int(campaign[key])) for key in ['id', 'campaign_status', 'failed', 'unknown'])


def send_campaign_alert(config, campaign):
    message = EmailMessage()
    message['Subject'] = 'Volitex AI Inbox — WhatsApp campaign failure alert'
    message['From'] = config['MAILER_SENDER_EMAIL']
    message['To'] = config['ALERT_EMAIL_TO']
    message.set_content(
        f"Environment: {config['ALERT_ENVIRONMENT']}\n"
        f"Account ID: {campaign['account_id']}\nCampaign ID: {campaign['id']}\n"
        f"Campaign status code: {campaign['campaign_status']}\n"
        f"Failed recipients: {campaign['failed']}\nUnknown recipients: {campaign['unknown']}\n\n"
        'Inspect the campaign ledger in the private Inbox console. Unknown means '
        'delivery may already have occurred: reconcile provider status before any '
        'operator-approved action. This monitor never retries or resends messages. '
        'No recipient phone numbers, campaign content or credentials are included.\n'
    )
    deliver_email(config, message)


def run_once(config, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with exclusive_lock(path.with_suffix('.lock')):
        if not path.exists():
            state = {'since': datetime.now(timezone.utc).isoformat(), 'notified': []}
            campaign_failures(config, state)
            save_state(path, state)
            return {'initialized': True, 'alerted': 0}
        state = json.loads(path.read_text(encoding='utf-8'))
        count = 0
        for campaign in campaign_failures(config, state):
            key = notification_key(campaign)
            if key in state['notified']:
                continue
            send_campaign_alert(config, campaign)
            state['notified'].append(key)
            save_state(path, state)
            count += 1
            if count == 20:
                break
        return {'initialized': False, 'alerted': count}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--state', type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(run_once(read_config(args.config), args.state)))
    except Exception as error:
        print(f'campaign alert monitor failed: {type(error).__name__}', file=sys.stderr)
        sys.exit(1)
