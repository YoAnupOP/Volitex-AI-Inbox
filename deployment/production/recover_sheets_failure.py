#!/usr/bin/env python3
"""Operator-reviewed replay for the approved sequential Sheets demo only."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from workflow_failure_alerts import exclusive_lock, read_config, save_state

GOOGLE_NODES = {'Read spreadsheet tab', 'Read headers and lead row', 'Write lead to reserved row'}


def docker(*args, input=None):
    result = subprocess.run(['docker', *args], input=input, text=True, capture_output=True, timeout=60)
    if result.returncode:
        raise RuntimeError('Recovery command failed; no automatic retry permitted')
    return result.stdout.strip()


def query(config, sql):
    return docker('exec', '-i', config['N8N_DATABASE_CONTAINER'], 'sh', '-c',
                  'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At', input=sql)


def fingerprint(workflow):
    return hashlib.sha256(json.dumps(workflow, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def event_id(data):
    # n8n's flatted references are decoded only along the authenticated-node path.
    table = json.loads(data)
    def value(item):
        return table[int(item)] if isinstance(item, str) and item.isdigit() else item
    result = value(table[0]['resultData'])
    if value(result['lastNodeExecuted']) not in GOOGLE_NODES:
        raise ValueError('Failure is not a reviewed Google HTTP-node failure')
    runs = value(result['runData'])
    run = value(value(runs['Authorize incoming message'])[0])
    main = value(value(run['data'])['main'])
    item = value(value(main[0])[0])
    authenticated = value(item['json'])
    event = value(authenticated['verifiedEvent'])
    return int(event['id'])


def decide(snapshot):
    if not snapshot['binding_matches']:
        return 'binding_mismatch'
    if not snapshot['incoming_public']:
        return 'not_public_incoming'
    if not snapshot['ai_owned']:
        return 'human_owned'
    if not snapshot['can_reply']:
        return 'reply_window_closed'
    if snapshot['existing_reply']:
        return 'reply_already_exists'
    if not snapshot['latest_incoming']:
        return 'newer_message_exists'
    return 'eligible'


RAILS = '''
Rails.logger.level = Logger::ERROR
message_id, account_id, inbox_id, bot_id, url, execute = ARGV
m = Message.find(Integer(message_id))
c = m.conversation
c.with_lock do
  bot = c.inbox.agent_bot
  key = "incoming:#{m.account_id}:#{m.inbox_id}:#{m.id}"
  existing = c.messages.where(sender: bot).where("(content_attributes #>> '{}')::jsonb ->> 'automation_delivery_id' = ?", key).first
  snapshot = {
    binding_matches: m.account_id == Integer(account_id) && m.inbox_id == Integer(inbox_id) && bot&.id == Integer(bot_id) && bot&.outgoing_url == url,
    incoming_public: m.incoming? && !m.private?,
    ai_owned: bot.present? && Conversations::AutomationOwnershipService.new(conversation: c, actor: bot).n8n_owner?(bot),
    can_reply: c.can_reply?, existing_reply: existing.present?,
    latest_incoming: c.messages.incoming.order(:id).last&.id == m.id
  }
  if execute == 'true' && snapshot.values_at(:binding_matches, :incoming_public, :ai_owned, :can_reply, :latest_incoming).all? && !snapshot[:existing_reply]
    # Queue admission is not downstream acceptance. The webhook and reply node
    # check ownership again after this lock is released.
    AgentBots::WebhookJob.perform_later(bot.outgoing_url, m.webhook_data.merge(event: 'message_created'), :agent_bot_webhook,
                                      secret: bot.secret, delivery_id: SecureRandom.uuid)
    snapshot[:dispatched] = true
  end
  puts 'RECOVERY_RESULT=' + snapshot.to_json
end
'''


def run(config, execution_id, state_path, execute=False, cause_resolved=False):
    workflow_id = config['RECOVERY_WORKFLOW_ID']
    # A reviewed workflow ID is an operator-owned internal identifier.
    if not all(c.isalnum() or c in '_-' for c in workflow_id):
        raise ValueError('Invalid approved workflow identifier')
    workflow = json.loads(query(config, f"SELECT json_build_object('nodes',nodes,'connections',connections,'settings',settings) FROM workflow_entity WHERE id='{workflow_id}';"))
    if fingerprint(workflow) != config['RECOVERY_WORKFLOW_SHA256']:
        raise ValueError('Workflow changed since review; recovery blocked')
    worker = json.loads(docker('inspect', config['N8N_WORKER_CONTAINER']))[0]
    if worker['Config']['Cmd'] != ['worker', '--concurrency=1']:
        raise ValueError('Sequential demo worker concurrency is not one')
    row = json.loads(query(config, f'''SELECT json_build_object('workflow',e."workflowId",'status',e.status,'data',d.data)
        FROM execution_entity e JOIN execution_data d ON d."executionId"=e.id WHERE e.id={int(execution_id)};'''))
    if row['workflow'] != workflow_id or row['status'] != 'error':
        raise ValueError('Execution is not a retained failure of the approved workflow')
    message_id = event_id(row['data'])
    args = [str(message_id), config['RECOVERY_ACCOUNT_ID'], config['RECOVERY_INBOX_ID'],
            config['RECOVERY_BOT_ID'], config['RECOVERY_WEBHOOK_URL'], str(execute).lower()]
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with exclusive_lock(state_path.with_suffix('.lock')):
        state = json.loads(state_path.read_text()) if state_path.exists() else {}
        if execute:
            if not cause_resolved:
                raise ValueError('Operator must verify the cause and downstream state first')
            if str(execution_id) in state:
                raise ValueError('Recovery already attempted; inspect outcome instead of retrying blindly')
            state[str(execution_id)] = {'message_id': message_id, 'status': 'dispatch_outcome_pending'}
            save_state(state_path, state)
        output = docker('exec', '-i', config['INBOX_WORKER_CONTAINER'], 'bundle', 'exec', 'rails', 'runner', '-', *args, input=RAILS)
        snapshot = json.loads(next(line.split('=', 1)[1] for line in output.splitlines() if line.startswith('RECOVERY_RESULT=')))
        decision = decide(snapshot)
        if execute:
            state[str(execution_id)]['status'] = 'queued_unverified' if snapshot.get('dispatched') else decision
            save_state(state_path, state)
        return {'execution_id': execution_id, 'message_id': message_id, 'decision': decision,
                'dispatched': snapshot.get('dispatched', False), 'recovery_accepted': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--state', type=Path, required=True)
    parser.add_argument('--execution-id', type=int, required=True)
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--cause-resolved', action='store_true')
    args = parser.parse_args()
    try:
        print(json.dumps(run(read_config(args.config), args.execution_id, args.state, args.execute, args.cause_resolved)))
    except Exception as error:
        print(f'Recovery blocked: {type(error).__name__}', file=sys.stderr)
        sys.exit(1)
