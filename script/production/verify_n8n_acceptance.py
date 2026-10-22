#!/usr/bin/env python3
"""Disposable, provider-stubbed acceptance. Never accepts an operator env/DB URL.

Requires a built Inbox image and its source SHA; no runtime source overlays.
No ports are published. Network is --internal. Existing staging is never read.
"""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import secrets
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / 'script/production/specs/n8n_acceptance'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app-image', required=True)
parser.add_argument('--app-postgres-image', required=True)
parser.add_argument('--source-sha', required=True)
parser.add_argument('--n8n-image', required=True)
parser.add_argument('--n8n-postgres-image', required=True)
parser.add_argument('--n8n-valkey-image', required=True)
args = parser.parse_args()
APP = args.app_image
SOURCE_SHA = args.source_sha
if not re.fullmatch(r'[0-9a-f]{40}', SOURCE_SHA):
    parser.error('--source-sha must be a full lowercase Git SHA')
OLD = 'n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c'
NEW = args.n8n_image
LEGACY_PG = 'postgres@sha256:f4c66b820c6f974249089d3d16d86a3698eae11e8746eb6644b2271031e91232'
PG = args.n8n_postgres_image
APP_PG = args.app_postgres_image
LEGACY_REDIS = 'valkey/valkey@sha256:3fbd2e3e4b6e85e046c1e7c215e8f79087bc0357789184305806664e320996f3'
REDIS = args.n8n_valkey_image
FAKE_NODE = 'node@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20'
PREFIX = f'volitex-acceptance-{os.getpid()}'
SCRATCH = Path(tempfile.mkdtemp(prefix=PREFIX + '-'))
os.chmod(SCRATCH, 0o700)
RUNTIME_FIXTURES = SCRATCH / 'fixtures'
RUNTIME_FIXTURES.mkdir(mode=0o755)
# Mount the child only: host access remains protected by SCRATCH (0700),
# while the container's uid 1000 can read synthetic fixtures on CI uid 1001.
(RUNTIME_FIXTURES / 'post.cjs').write_bytes((FIXTURES / 'post.cjs').read_bytes())
CONTAINERS = []
NETWORKS = []
APP_NETWORK = PREFIX + '-app'
N8N_NETWORK = PREFIX + '-n8n'
ROLE_NETWORKS = {
    'app-db': (APP_NETWORK, '172.30.246.'), 'app-redis': (APP_NETWORK, '172.30.246.'),
    'inbox': (APP_NETWORK, '172.30.246.'), 'app-worker': (APP_NETWORK, '172.30.246.'),
    'fake': (APP_NETWORK, '172.30.246.'), 'n8n-db': (N8N_NETWORK, '172.30.247.'),
    'redis': (N8N_NETWORK, '172.30.247.'), 'n8n-main': (N8N_NETWORK, '172.30.247.'),
    'n8n-worker': (N8N_NETWORK, '172.30.247.'),
}
RESULTS = {'application_image': APP, 'application_source': SOURCE_SHA, 'candidate_n8n_image': NEW,
           'candidate_inbox_postgres_image': APP_PG, 'candidate_n8n_postgres_image': PG, 'candidate_n8n_valkey_image': REDIS,
           'runtime_policy_sha256': hashlib.sha256((ROOT / 'deployment/n8n/runtime-policy.env').read_bytes()).hexdigest()}


def command(*args, check=True, timeout=300):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    with (SCRATCH / 'commands.log').open('a') as stream:
        stream.write('COMMAND: ' + ' '.join(args[:3]) + '\n')
        # Seed output is a protected IPC channel, not diagnostic log material.
        output = '\n'.join('SYNTHETIC_FIXTURE=[redacted]' if line.startswith('SYNTHETIC_FIXTURE=') else line
                           for line in result.stdout.splitlines())
        stream.write(output + '\n' + result.stderr)
    if check and result.returncode:
        raise RuntimeError(f'Command failed (exit {result.returncode}); protected evidence: {SCRATCH}')
    return result.stdout.strip()


def write_json(name, value):
    path = RUNTIME_FIXTURES / name
    path.write_text(json.dumps(value))
    os.chmod(path, 0o644)


def write_env(name, values):
    path = SCRATCH / name
    path.write_text(''.join(f'{k}={v}\n' for k, v in values.items()))
    os.chmod(path, 0o600)
    return str(path)


def start(role, image, ip, env=None, mounts=(), args=(), alias=None, entrypoint=None):
    name = PREFIX + '-' + role
    network, subnet = ROLE_NETWORKS[role]
    options = ['docker', 'create', '--name', name, '--network', network, '--ip', subnet + ip.rsplit('.', 1)[1]]
    if role in ('n8n-main', 'n8n-worker'):
        options += ['--init', '--cap-drop=ALL', '--security-opt=no-new-privileges:true', '--pids-limit=256']
    if alias:
        options += ['--network-alias', alias]
    if env:
        options += ['--env-file', env]
    for mount in mounts:
        options += ['-v', mount]
    if entrypoint:
        options += ['--entrypoint', entrypoint]
    command(*options, image, *args)
    CONTAINERS.append(name)
    if role in ('app-worker', 'n8n-main'):
        extra = ['--alias', alias] if alias else []
        command('docker', 'network', 'connect', '--ip', ip, *extra, PREFIX, name)
    if role == 'fake':
        command('docker', 'network', 'connect', '--ip', '172.30.247.30', '--alias', 'probe-fake', N8N_NETWORK, name)
    command('docker', 'start', name)
    return name


def wait_for(predicate, label, timeout=180, interval=2):
    until = time.monotonic() + timeout
    while time.monotonic() < until:
        try:
            if predicate():
                RESULTS[label] = 'PASS'
                return
        except (RuntimeError, ValueError, json.JSONDecodeError):
            pass
        time.sleep(interval)
    raise RuntimeError(f'Timeout: {label}; protected evidence: {SCRATCH}')


def sql(database, statement):
    return command('docker', 'exec', n8n_db, 'psql', '-U', 'postgres', '-d', database, '-Atc', statement)


def rails(code, *args):
    return command('docker', 'exec', inbox, 'bundle', 'exec', 'rails', 'runner', code, *args)


def fake_state():
    code = 'fetch("http://probe-fake:8080/state").then(r=>r.text()).then(console.log)'
    return json.loads(command('docker', 'exec', fake, 'node', '-e', code))


def emit_event(content='Volitex round trip'):
    output = rails('c=Conversation.first; m=c.messages.create!(account:c.account,inbox:c.inbox,sender:c.contact,message_type: :incoming,content:ARGV.fetch(0)); puts "EVENT="+m.webhook_data.merge(event:"message_created").to_json', content)
    event = json.loads(next(line[6:] for line in output.splitlines() if line.startswith('EVENT=')))
    write_json('event.json', event)
    return event


def n8n_start(image, database='n8n', suffix=''):
    global n8n_main, n8n_worker
    config = dict(n8n_env, DB_POSTGRESDB_DATABASE=database)
    env = write_env('n8n.env', config)
    shared_mounts = [f'{RUNTIME_FIXTURES}:/fixtures:ro']
    if image == OLD:
        shared_mounts.append(f'{ROOT}/deployment/n8n/custom:/opt/volitex/n8n-custom:ro')
    mounts = shared_mounts + [f'{PREFIX}-n8n-data{suffix}:/home/node/.n8n']
    n8n_main = start('n8n-main', image, '172.30.248.10', env, mounts, ['start'], 'probe-n8n')
    wait_for(lambda: command('docker', 'exec', n8n_main, 'wget', '-qO-', 'http://127.0.0.1:5678/healthz/readiness', check=False) != '', 'n8n_readiness')
    n8n_worker = start('n8n-worker', image, '172.30.248.11', env, shared_mounts, ['worker', '--concurrency=2'])
    wait_for(lambda: command('docker', 'exec', n8n_worker, 'wget', '-qO-', 'http://127.0.0.1:5678/healthz/readiness', check=False) != '', 'worker_readiness')


def stop_n8n():
    command('docker', 'stop', '--time', '30', n8n_worker, n8n_main)
    command('docker', 'rm', n8n_worker, n8n_main)
    CONTAINERS.remove(n8n_worker)
    CONTAINERS.remove(n8n_main)


try:
    marker = command('docker', 'run', '--rm', '--network', 'none', '--entrypoint', 'cat', APP, '/app/.git_sha')
    if marker != SOURCE_SHA:
        raise RuntimeError('Application image source does not match --source-sha')
    RESULTS['application_source_marker'] = 'PASS'
    for network, subnet in ((APP_NETWORK, '172.30.246.0/24'), (N8N_NETWORK, '172.30.247.0/24'), (PREFIX, '172.30.248.0/24')):
        command('docker', 'network', 'create', '--internal', '--subnet', subnet, network)
        NETWORKS.append(network)
    for name in ('app-db', 'n8n-db', 'n8n-db-upgraded', 'redis', 'app-redis', 'app-storage', 'n8n-data', 'n8n-data-restore'):
        command('docker', 'volume', 'create', PREFIX + '-' + name)
    password = secrets.token_hex(24)
    db_env = write_env('db.env', {'POSTGRES_PASSWORD': password})
    n8n_db = start('n8n-db', LEGACY_PG, '172.30.248.5', db_env, [f'{PREFIX}-n8n-db:/var/lib/postgresql/data'], alias='probe-n8n-db')
    app_db = start('app-db', APP_PG, '172.30.248.6', db_env, [f'{PREFIX}-app-db:/var/lib/postgresql/data'], alias='probe-app-db')
    redis = start('redis', LEGACY_REDIS, '172.30.248.7', mounts=[f'{PREFIX}-redis:/data'], args=['valkey-server', '--appendonly', 'yes', '--maxmemory-policy', 'noeviction'], alias='probe-redis')
    start('app-redis', REDIS, '172.30.248.8', mounts=[f'{PREFIX}-app-redis:/data'], args=['valkey-server', '--appendonly', 'yes', '--maxmemory-policy', 'noeviction'], alias='probe-app-redis')
    fake = start('fake', FAKE_NODE, '172.30.248.30', mounts=[f'{FIXTURES}:/code:ro', f'{SCRATCH}:/state'], args=['node', '/code/fake.cjs'], alias='probe-fake')
    if command('docker', 'exec', app_db, 'cat', '/opt/volitex/inbox-postgres-source-sha') != SOURCE_SHA:
        raise RuntimeError('Inbox PostgreSQL image source mismatch')
    RESULTS['inbox_postgres_source_marker'] = 'PASS'
    for db in (app_db, n8n_db):
        wait_for(lambda db=db: 'accepting connections' in command('docker', 'exec', db, 'pg_isready', '-U', 'postgres', check=False), 'postgres_ready')
    sql('postgres', 'CREATE DATABASE n8n')
    binding = [{'account_id': 1, 'agent_bot_id': 1, 'url': 'http://probe-n8n:5678/webhook/volitex-staging-account-1', 'ip_addresses': ['172.30.248.10']}]
    app_values = {'RAILS_ENV': 'production', 'NODE_ENV': 'production', 'INSTALLATION_ENV': 'docker',
                  'FRONTEND_URL': 'http://probe-inbox:3000', 'FORCE_SSL': 'false', 'SECRET_KEY_BASE': secrets.token_hex(64),
                  'POSTGRES_HOST': 'probe-app-db', 'POSTGRES_DATABASE': 'n8n_acceptance', 'POSTGRES_USERNAME': 'postgres',
                  'POSTGRES_PASSWORD': password, 'REDIS_URL': 'redis://probe-app-redis:6379/0', 'SIDEKIQ_CONCURRENCY': '2',
                  'RAILS_LOG_TO_STDOUT': 'true', 'ACTIVE_STORAGE_SERVICE': 'local', 'WHATSAPP_CLOUD_BASE_URL': 'http://probe-fake:8080/meta',
                  'SAFE_FETCH_ALLOW_PRIVATE_NETWORK': 'false', 'N8N_AGENT_BOT_TRANSPORTS': json.dumps(binding, separators=(',', ':'))}
    for key in ('PRIMARY_KEY', 'DETERMINISTIC_KEY', 'KEY_DERIVATION_SALT'):
        app_values['ACTIVE_RECORD_ENCRYPTION_' + key] = secrets.token_hex(32)
    app_env = write_env('app.env', app_values)
    app_mounts = [f'{FIXTURES}:/probe:ro', f'{PREFIX}-app-storage:/app/storage']
    inbox = start('inbox', APP, '172.30.248.20', app_env, app_mounts, ['-c', 'sleep infinity'], 'probe-inbox', 'sh')
    command('docker', 'exec', inbox, 'bundle', 'exec', 'rails', 'db:chatwoot_prepare')
    output = command('docker', 'exec', inbox, 'bundle', 'exec', 'rails', 'runner', '/probe/seed.rb')
    fixture = json.loads(next(line.split('=', 1)[1] for line in output.splitlines() if line.startswith('SYNTHETIC_FIXTURE=')))
    assert fixture['account_id'] == 1 and fixture['bot_id'] == 1
    # Replace the sleeping disposable shell by the actual web process.
    command('docker', 'rm', '-f', inbox)
    CONTAINERS.remove(inbox)
    inbox = start('inbox', APP, '172.30.248.20', app_env, app_mounts, ['bundle', 'exec', 'rails', 's', '-b', '0.0.0.0', '-p', '3000'], 'probe-inbox')
    wait_for(lambda: command('docker', 'exec', inbox, 'curl', '-fsS', 'http://127.0.0.1:3000/health', check=False) != '', 'inbox_health')
    # n8n env schema, with synthetic secrets only and no host port bindings.
    n8n_env = {}
    policy_lines = (ROOT / 'deployment/n8n/runtime-policy.env').read_text().splitlines()
    for line in (ROOT / 'deployment/.env.n8n.example').read_text().splitlines() + policy_lines:
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            n8n_env[key] = secrets.token_hex(32) if '<' in value else value
    n8n_env.update({'DB_POSTGRESDB_HOST': 'probe-n8n-db', 'DB_POSTGRESDB_USER': 'postgres', 'DB_POSTGRESDB_PASSWORD': password,
                    'N8N_CUSTOM_EXTENSIONS': '/opt/volitex/n8n-custom',
                    'QUEUE_BULL_REDIS_HOST': 'probe-redis', 'QUEUE_BULL_REDIS_PASSWORD': '', 'QUEUE_BULL_REDIS_DB': '1',
                    'QUEUE_BULL_PREFIX': 'synthetic-acceptance', 'N8N_HOST': 'probe-n8n', 'N8N_PROTOCOL': 'http',
                    'N8N_WEBHOOK_URL': 'http://probe-n8n:5678', 'N8N_EDITOR_BASE_URL': 'http://probe-n8n:5678',
                    'N8N_SSRF_ALLOWED_HOSTNAMES': 'probe-fake', 'EXECUTIONS_DATA_SAVE_ON_SUCCESS': 'all',
                    'N8N_SMTP_HOST': 'smtp.invalid', 'N8N_SMTP_SENDER': 'Synthetic <synthetic@example.invalid>'})
    n8n_start(OLD)
    blocked_probe = 'require "socket"; begin; Socket.tcp("172.30.248.10",5678,connect_timeout:2).close; abort "Unexpected private-network bypass"; rescue Errno::EHOSTUNREACH,Errno::ENETUNREACH,Errno::ECONNREFUSED,Errno::ETIMEDOUT; puts "BLOCKED"; end'
    assert command('docker', 'exec', inbox, 'ruby', '-e', blocked_probe) == 'BLOCKED'
    RESULTS['rails_cannot_reach_private_n8n'] = 'PASS'
    credential_data = {'baseUrl': 'http://probe-fake:8080', 'accountId': fixture['account_id'], 'inboxId': fixture['inbox_id'],
                       'botId': fixture['bot_id'], 'apiToken': fixture['api_token'], 'signingSecret': fixture['signing_secret']}
    write_json('credentials-data.json', credential_data)
    write_json('credentials.json', [{'id': 'VolitexStagingAgentBot', 'name': 'Synthetic scoped bot', 'type': 'volitexInbox', 'data': credential_data}])
    workflow = json.loads((ROOT / 'deployment/n8n/inbox-reply.workflow.json').read_text())
    workflow['settings']['saveDataSuccessExecution'] = 'all'
    write_json('workflow.json', workflow)
    n8n_owner = sql('n8n', 'SELECT id FROM "user" LIMIT 1')
    command('docker', 'exec', n8n_main, 'n8n', 'import:credentials', '--input=/fixtures/credentials.json', '--userId=' + n8n_owner)
    command('docker', 'exec', n8n_main, 'n8n', 'import:workflow', '--input=/fixtures/workflow.json', '--userId=' + n8n_owner)
    command('docker', 'exec', n8n_main, 'n8n', 'publish:workflow', '--id=VolitexStagingReply')
    command('docker', 'restart', n8n_main, n8n_worker)
    wait_for(lambda: command('docker', 'exec', n8n_main, 'wget', '-qO-', 'http://127.0.0.1:5678/healthz/readiness', check=False) != '', 'old_n8n_active')
    worker = start('app-worker', APP, '172.30.248.21', app_env, app_mounts, ['bundle', 'exec', 'sidekiq', '-C', 'config/sidekiq.yml'])
    bridge = json.loads(command('docker', 'network', 'inspect', PREFIX))[0]
    assert {member['Name'] for member in bridge['Containers'].values()} == {worker, n8n_main}
    RESULTS['automation_bridge_only_worker_and_main'] = 'PASS'
    emit_event()
    wait_for(lambda: fake_state()['providerCalls'] == 1, 'old_authenticated_round_trip')
    command('docker', 'stop', '--time', '30', worker)
    stop_n8n()
    backup = subprocess.run(['docker', 'exec', n8n_db, 'pg_dump', '-U', 'postgres', '-Fc', 'n8n'], capture_output=True, check=True).stdout
    (SCRATCH / 'prior.dump').write_bytes(backup)
    os.chmod(SCRATCH / 'prior.dump', 0o600)
    RESULTS['prior_backup_sha256'] = hashlib.sha256(backup).hexdigest()
    command('docker', 'run', '--rm', '-v', PREFIX + '-n8n-data:/from:ro', '-v', str(SCRATCH) + ':/out', 'alpine:3.23', 'tar', 'cf', '/out/prior-data.tar', '-C', '/from', '.')
    # A libc/distro change requires logical restore into a fresh cluster. Keep
    # the original database volume intact; never attach it to the Alpine image.
    command('docker', 'stop', '--time', '30', n8n_db)
    command('docker', 'rm', n8n_db)
    CONTAINERS.remove(n8n_db)
    n8n_db = start('n8n-db', PG, '172.30.248.5', db_env,
                   [f'{PREFIX}-n8n-db-upgraded:/var/lib/postgresql/data'], alias='probe-n8n-db')
    wait_for(lambda: 'accepting connections' in command('docker', 'exec', n8n_db, 'pg_isready', '-U', 'postgres', check=False), 'new_postgres_ready')
    sql('postgres', 'CREATE DATABASE n8n')
    command('docker', 'cp', str(SCRATCH / 'prior.dump'), n8n_db + ':/tmp/prior.dump')
    command('docker', 'exec', n8n_db, 'pg_restore', '--exit-on-error', '-U', 'postgres', '-d', 'n8n', '/tmp/prior.dump')
    RESULTS['postgres_logical_migration_into_fresh_cluster'] = 'PASS'
    # Redis/Valkey AOF is portable across these same-major images. Prove it
    # with persisted state while all application/n8n queue writers are stopped.
    command('docker', 'exec', redis, 'valkey-cli', 'SET', 'volitex:migration:canary', 'preserved')
    command('docker', 'exec', redis, 'valkey-cli', 'LPUSH', 'volitex:migration:list', 'queued')
    command('docker', 'stop', '--time', '30', redis)
    command('docker', 'rm', redis)
    CONTAINERS.remove(redis)
    redis = start('redis', REDIS, '172.30.248.7', mounts=[f'{PREFIX}-redis:/data'],
                  args=['valkey-server', '--appendonly', 'yes', '--maxmemory-policy', 'noeviction'], alias='probe-redis')
    wait_for(lambda: command('docker', 'exec', redis, 'valkey-cli', 'PING', check=False) == 'PONG', 'new_valkey_ready')
    assert command('docker', 'exec', redis, 'valkey-cli', 'GET', 'volitex:migration:canary') == 'preserved'
    assert command('docker', 'exec', redis, 'valkey-cli', 'LPOP', 'volitex:migration:list') == 'queued'
    RESULTS['valkey_aof_state_migration'] = 'PASS'
    n8n_start(NEW)
    command('docker', 'start', worker)
    emit_event()
    wait_for(lambda: fake_state()['providerCalls'] == 2, 'candidate_authenticated_round_trip')
    for mode, status in [('invalid', '401'), ('foreign', '403'), ('replay', '200')]:
        actual = command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', mode)
        assert actual == status, mode + ' rejected incorrectly'
    time.sleep(3)
    assert fake_state()['providerCalls'] == 2
    RESULTS['invalid_auth_foreign_tenant_replay'] = 'PASS'
    # Pause the worker after the real Inbox API commits, before its response returns.
    command('docker', 'exec', fake, 'node', '-e', 'fetch("http://127.0.0.1:8080/delay-next").then(r=>r.text()).then(console.log)')
    emit_event()
    wait_for(lambda: (SCRATCH / 'api-committed').exists(), 'api_committed_before_worker_kill', interval=0.1)
    assert time.time() - (SCRATCH / 'api-committed').stat().st_mtime < 1
    command('docker', 'kill', n8n_worker)
    assert not (SCRATCH / 'api-response-released').exists()
    command('docker', 'stop', '--time', '30', worker)
    command('docker', 'start', n8n_worker)
    wait_for(lambda: command('docker', 'exec', n8n_worker, 'wget', '-qO-', 'http://127.0.0.1:5678/healthz/readiness', check=False) != '',
             'worker_restarted_after_kill')
    owner = command('docker', 'exec', app_db, 'psql', '-U', 'postgres', '-d', 'n8n_acceptance', '-Atc',
                    "SELECT custom_attributes->>'automation_owner' FROM conversations LIMIT 1")
    RESULTS['owner_after_interruption'] = owner
    if owner == 'human':
        rails('Conversations::AutomationOwnershipService.new(conversation:Conversation.first,actor:User.first).enable_n8n!')
        RESULTS['operator_resume_after_handoff'] = 'explicit ownership service, not bypassed'
    command('docker', 'start', worker)
    before_replay = fake_state()['apiPosts']
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'replay') == '200'
    wait_for(lambda: fake_state()['apiPosts'] > before_replay, 'repeated_api_side_effect_attempted')
    wait_for(lambda: fake_state()['providerCalls'] == 3, 'interrupted_reply_replay_one_provider_call')
    time.sleep(5)
    assert fake_state()['providerCalls'] == 3
    RESULTS['interrupted_side_effect_duplicate_safety'] = 'PASS'
    command('docker', 'stop', '--time', '30', n8n_worker)
    emit_event()
    time.sleep(1)
    assert fake_state()['providerCalls'] == 3
    command('docker', 'start', n8n_worker)
    wait_for(lambda: fake_state()['providerCalls'] == 4, 'queued_work_recovered_after_worker_start')
    rails('Conversations::AutomationOwnershipService.new(conversation:Conversation.first,actor:User.first).handoff_to_human!')
    emit_event()
    before = fake_state()
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'replay') == '200'
    time.sleep(3)
    assert fake_state() == before
    RESULTS['human_handoff_no_api_post'] = 'PASS'
    wait_for(lambda: sql('n8n', "SELECT count(*) FROM execution_entity WHERE status IN ('running','new','waiting')") == '0',
             'interrupted_execution_terminal', timeout=240)
    RESULTS['candidate_execution_states'] = sql('n8n', 'SELECT status,count(*) FROM execution_entity GROUP BY status ORDER BY status')
    assert int(sql('n8n', "SELECT count(*) FROM execution_entity WHERE status IN ('error', 'crashed') AND COALESCE(\"stoppedAt\", \"startedAt\") >= now() - interval '5 minutes'")) > 0
    RESULTS['crashed_execution_monitor_query'] = 'PASS'
    # Pause event delivery and stop all n8n writers before changing a published graph.
    # Importing beside a running main can leave its old active graph in service.
    command('docker', 'stop', '--time', '30', worker)
    stop_n8n()
    # Exercise general production operations, not only the guarded smoke phrase.
    rails('Conversations::AutomationOwnershipService.new(conversation:Conversation.first,actor:User.first).enable_n8n!')
    workflow['nodes'][1]['parameters']['operation'] = 'authorize'
    workflow['nodes'][3]['parameters'] = {'operation': 'sendReply', 'content': 'Synthetic real-estate workflow response'}
    rejected = copy.deepcopy(workflow['nodes'][2])
    rejected['id'] = 'rejected-automation'
    rejected['name'] = 'Rejected automation'
    workflow['nodes'].append(rejected)
    workflow['connections']['Validate webhook']['main'] = [
        [{'node': 'Webhook result', 'type': 'main', 'index': 0}],
        [{'node': 'Rejected automation', 'type': 'main', 'index': 0}],
    ]
    write_json('production-contract.json', workflow)
    cli = ['docker', 'run', '--rm', '--network', N8N_NETWORK, '--env-file', str(SCRATCH / 'n8n.env'),
           '-v', f'{RUNTIME_FIXTURES}:/fixtures:ro',
           NEW]
    command(*cli, 'import:workflow', '--input=/fixtures/production-contract.json', '--userId=' + n8n_owner)
    command(*cli, 'publish:workflow', '--id=VolitexStagingReply')
    active_nodes = json.loads(sql("n8n", """SELECT h.nodes FROM workflow_history h JOIN workflow_entity w ON h."versionId"=w."activeVersionId" WHERE w.id='VolitexStagingReply'"""))
    assert [node['parameters']['operation'] for node in active_nodes if node['type'] == 'CUSTOM.volitexReply'] == ['authorize', 'sendReply']
    n8n_start(NEW)
    command('docker', 'start', worker)
    RESULTS['production_contract_ready'] = 'PASS'
    emit_event('Can I schedule a site visit?')
    wait_for(lambda: fake_state()['providerCalls'] == 5, 'ordinary_customer_configured_reply')
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'invalid') == '401'
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'foreign') == '403'
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'replay') == '200'
    time.sleep(3)
    assert fake_state()['providerCalls'] == 5
    RESULTS['production_rejection_and_reply_replay'] = 'PASS'
    rails('Conversations::AutomationOwnershipService.new(conversation:Conversation.first,actor:User.first).handoff_to_human!')
    emit_event('Please connect me to an agent')
    before = fake_state()
    assert command('docker', 'exec', n8n_main, 'node', '/fixtures/post.cjs', 'replay') == '200'
    time.sleep(3)
    assert fake_state() == before
    RESULTS['production_handoff_no_api_post'] = 'PASS'
    command('docker', 'stop', '--time', '30', worker)
    stop_n8n()
    sql('postgres', 'CREATE DATABASE n8n_restore')
    command('docker', 'cp', str(SCRATCH / 'prior.dump'), n8n_db + ':/tmp/prior.dump')
    command('docker', 'exec', n8n_db, 'pg_restore', '-U', 'postgres', '-d', 'n8n_restore', '/tmp/prior.dump')
    command('docker', 'run', '--rm', '-v', PREFIX + '-n8n-data-restore:/to', '-v', str(SCRATCH) + ':/out:ro', 'alpine:3.23', 'tar', 'xf', '/out/prior-data.tar', '-C', '/to')
    rails('Conversations::AutomationOwnershipService.new(conversation:Conversation.first,actor:User.first).enable_n8n!')
    n8n_start(OLD, 'n8n_restore', '-restore')
    command('docker', 'start', worker)
    emit_event()
    wait_for(lambda: fake_state()['providerCalls'] == 6, 'rollback_restored_credentials_and_workflow')
    RESULTS['provider_calls'] = fake_state()['providerCalls']
    RESULTS['result'] = 'PASS'
except Exception as error:
    RESULTS['result'] = 'FAIL'
    RESULTS['failure'] = type(error).__name__ + ': ' + str(error)[:200]
    # Preserve bounded, non-secret outcomes before disposable resources vanish.
    # Raw execution data, webhook headers and credential values are never emitted.
    try:
        if 'fake' in globals():
            RESULTS['failure_provider_state'] = fake_state()
        if 'n8n_db' in globals() and 'n8n_main' in globals():
            rows = sql('n8n', """SELECT coalesce(json_agg(t), '[]') FROM (
                SELECT e.id,e.status,d.data FROM execution_entity e
                LEFT JOIN execution_data d ON d."executionId"=e.id
                WHERE e."workflowId"='VolitexStagingReply' ORDER BY e.id DESC LIMIT 6
            ) t""")
            decoder = """const flatted = require('/usr/local/lib/node_modules/n8n/node_modules/flatted');
                let input = ''; process.stdin.on('data', chunk => input += chunk);
                process.stdin.on('end', () => console.log(JSON.stringify(JSON.parse(input).map(row => {
                    const result = row.data ? flatted.parse(row.data).resultData || {} : {};
                    const statuses = new Set(['reply_accepted','human_owned','authenticated_event',
                        'automation_allowed','invalid_authentication','tenant_context_rejected',
                        'inbox_unavailable','ignored_test_phrase','reply_rejected','inbox_api_rejected']);
                    return {id: row.id, status: row.status, lastNode: result.lastNodeExecuted,
                        errorName: result.error?.name,
                        nodes: Object.entries(result.runData || {}).map(([node, runs]) => ({node,
                            errorNames: runs.map(run => run.error?.name).filter(Boolean),
                            outcomes: runs.flatMap(run => (run.data?.main || []).flat()
                                .filter(Boolean).map(item => item.json?.verification?.status || item.json?.status)
                                .filter(status => statuses.has(status)))
                        }))};
                }))));"""
            decoded = subprocess.run(['docker', 'exec', '-i', n8n_main, 'node', '-e', decoder],
                                     input=rows, capture_output=True, text=True, check=True, timeout=30)
            RESULTS['failure_execution_outcomes'] = json.loads(decoded.stdout)
    except Exception as diagnostic_error:
        RESULTS['failure_diagnostics_unavailable'] = type(diagnostic_error).__name__
    raise
finally:
    for container in CONTAINERS:
        command('docker', 'logs', container, check=False)
    for container in reversed(CONTAINERS):
        command('docker', 'rm', '-f', container, check=False)
    for network in reversed(NETWORKS):
        command('docker', 'network', 'rm', network, check=False)
    (SCRATCH / 'result.json').write_text(json.dumps(RESULTS, indent=2))
    print(json.dumps({'evidence': str(SCRATCH), **RESULTS}, indent=2))
