#!/usr/bin/env python3
"""Read n8n execution metadata and email failures; never replay workflows."""
import argparse
import contextlib
import json
import os
from pathlib import Path
import smtplib
import ssl
import subprocess
import sys
from datetime import datetime, timezone
from email.message import EmailMessage


def read_config(path):
    values = {}
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        if line and not line.startswith('#'):
            key, value = line.split('=', 1)
            values[key] = value.strip()
    return values


@contextlib.contextmanager
def exclusive_lock(path):
    with path.open('a+b') as stream:
        stream.seek(0)
        if os.name == 'nt':
            import msvcrt
            if path.stat().st_size == 0:
                stream.write(b'0')
                stream.flush()
            stream.seek(0)
            msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        try:
            yield
        finally:
            stream.seek(0)
            if os.name == 'nt':
                msvcrt.locking(stream.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(stream, fcntl.LOCK_UN)


def save_state(path, state):
    temporary = path.with_suffix('.tmp')
    with temporary.open('w', encoding='utf-8') as stream:
        json.dump(state, stream, indent=2)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def failed_executions(config, state):
    # Only execution metadata is queried. No execution_data, credentials or bodies.
    since = datetime.fromisoformat(state['since']).astimezone(timezone.utc).isoformat()
    notified = [str(int(value)) for value in state['notified']]
    exclusions = ','.join(notified) or '0'
    query = f'''SELECT row_to_json(e) FROM (
      SELECT id::text AS id, "workflowId" AS workflow_id, status,
             COALESCE("stoppedAt", "startedAt") AS occurred_at
      FROM execution_entity
      WHERE status IN ('error', 'crashed')
        AND COALESCE("stoppedAt", "startedAt") >= '{since}'::timestamptz
        AND id NOT IN ({exclusions})
      ORDER BY id LIMIT 20
    ) e;'''
    if config.get('N8N_DATABASE_CONTAINER'):
        command = ['docker', 'exec', '-i', config['N8N_DATABASE_CONTAINER'], 'sh', '-c',
                   'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At']
        environment = None
    else:
        command = ['psql', '-X', '-v', 'ON_ERROR_STOP=1', '-At']
        environment = dict(os.environ, PGDATABASE=config['N8N_DATABASE_URL'])
    result = subprocess.run(command, input=query, text=True, capture_output=True,
                            env=environment, timeout=30)
    if result.returncode:
        # psql diagnostics can contain connection details; never echo them.
        raise RuntimeError('n8n metadata query failed')
    return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]


def send_alert(config, execution):
    message = EmailMessage()
    message['Subject'] = 'Volitex AI Inbox — workflow failure alert'
    message['From'] = config['MAILER_SENDER_EMAIL']
    message['To'] = config['ALERT_EMAIL_TO']
    message.set_content(
        f"Environment: {config['ALERT_ENVIRONMENT']}\n"
        f"Workflow ID: {execution['workflow_id']}\n"
        f"Execution ID: {execution['id']}\n"
        f"Category: {execution['status']}\n"
        f"Time: {execution['occurred_at']}\n\n"
        'Review the execution in your private n8n console. Check current human ownership '
        'and downstream committed state before any approved replay. This alert does not '
        'retry or repair the workflow. No customer message or credentials are included.\n'
    )
    deliver_email(config, message)


def deliver_email(config, message):
    with smtplib.SMTP(config['SMTP_ADDRESS'], int(config['SMTP_PORT']), timeout=20) as smtp:
        smtp.ehlo()
        smtp.starttls(context=ssl.create_default_context())
        smtp.ehlo()
        smtp.login(config['SMTP_USERNAME'], config['SMTP_PASSWORD'].replace(' ', ''))
        if smtp.send_message(message):
            raise RuntimeError('SMTP recipient rejected')


def run_once(config, state_path):
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with exclusive_lock(state_path.with_suffix('.lock')):
        if not state_path.exists():
            state = {'since': datetime.now(timezone.utc).isoformat(), 'notified': []}
            # Prove access before recording the initial monitoring boundary.
            failed_executions(config, state)
            save_state(state_path, state)
            return {'initialized': True, 'alerted': 0}
        state = json.loads(state_path.read_text(encoding='utf-8'))
        count = 0
        for execution in failed_executions(config, state):
            send_alert(config, execution)
            state['notified'].append(str(int(execution['id'])))
            save_state(state_path, state)
            count += 1
        return {'initialized': False, 'alerted': count}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--state', type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(run_once(read_config(args.config), args.state)))
    except Exception as error:
        # Neither SMTP responses nor exception strings may expose private data.
        print(f'workflow alert monitor failed: {type(error).__name__}', file=sys.stderr)
        sys.exit(1)
