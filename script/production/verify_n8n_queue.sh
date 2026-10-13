#!/usr/bin/env bash
# Private disposable queue probe, not the customer automation workflow.
set -euo pipefail
prefix="volitex-n8n-probe-${GITHUB_RUN_ID:-$$}"
scratch=$(mktemp -d)
umask 077
python3 - "$scratch" "${1:-}" <<'PY'
import pathlib
import secrets
import shlex
import sys
scratch = pathlib.Path(sys.argv[1])
values = {}
for line in pathlib.Path('deployment/.env.n8n.example').read_text().splitlines():
    if line and not line.startswith('#') and '=' in line:
        key, value = line.split('=', 1)
        values[key] = secrets.token_hex(32) if '<' in value else value
values.update({
    'N8N_HOST': 'n8n-main', 'N8N_PROTOCOL': 'http',
    'N8N_EDITOR_BASE_URL': 'http://n8n-main:5678', 'N8N_WEBHOOK_URL': 'http://n8n-main:5678',
    'N8N_SMTP_HOST': 'smtp.invalid', 'N8N_SMTP_USER': 'synthetic',
    'N8N_SMTP_SENDER': 'Synthetic <synthetic@example.invalid>',
    'EXECUTIONS_DATA_SAVE_ON_SUCCESS': 'all',
})
if sys.argv[2]:
    values['N8N_IMAGE'] = sys.argv[2]
(scratch / '.env').write_text(''.join(f'{key}={shlex.quote(value)}\n' for key, value in values.items()))
fixture = pathlib.Path('script/production/specs/n8n_queue_probe.json').resolve()
(scratch / 'overlay.yaml').write_text(f'services:\n  n8n-main:\n    volumes:\n      - "{fixture}:/fixtures/probe.json:ro"\n')
PY
set -a
# Every value comes from the newly generated disposable environment, not operator credentials.
source "$scratch/.env"
set +a
compose=(docker compose -p "$prefix" --env-file "$scratch/.env" -f deployment/n8n-queue.compose.yaml -f "$scratch/overlay.yaml")
cleanup() {
  # Retain this probe's named volumes; existing deployment data is never removed.
  "${compose[@]}" down >/dev/null 2>&1 || true
  rm -rf "$scratch"
}
trap cleanup EXIT
"${compose[@]}" config --quiet
"${compose[@]}" up -d n8n-main >/dev/null
ready=false
for attempt in $(seq 1 90); do
  if "${compose[@]}" exec -T n8n-main wget -qO- http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
test "$ready" = true
"${compose[@]}" run --rm --no-deps --entrypoint n8n n8n-main import:workflow --input=/fixtures/probe.json
"${compose[@]}" run --rm --no-deps --entrypoint n8n n8n-main publish:workflow --id=VolitexSyntheticProbe
"${compose[@]}" restart n8n-main >/dev/null
ready=false
for attempt in $(seq 1 90); do
  if "${compose[@]}" exec -T n8n-main wget -qO- http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
test "$ready" = true
probe='const http=require("http");const request=http.request("http://127.0.0.1:5678/webhook/volitex-candidate-probe",{method:"POST",headers:{"content-type":"application/json"}},response=>{let body="";response.on("data",chunk=>body+=chunk);response.on("end",()=>{if(response.statusCode!==200)process.exit(1);const result=JSON.parse(body);if(result.delivery!=="synthetic-delivery"||result.event!=="message_created")process.exit(1);console.log("Synthetic webhook response verified");});});request.setTimeout(Number(process.argv[1]),()=>{request.destroy();process.exit(28)});request.on("error",()=>process.exit(1));request.end(JSON.stringify({delivery_id:"synthetic-delivery",event:"message_created"}));'
# With no worker, a response-node webhook must wait in the queue.
set +e
"${compose[@]}" exec -T n8n-main node -e "$probe" 3000
status=$?
set -e
test "$status" = 28
"${compose[@]}" up -d n8n-worker >/dev/null
"${compose[@]}" exec -T n8n-main node -e "$probe" 60000
executions=$("${compose[@]}" exec -T n8n-postgres psql -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -tAc "SELECT count(*) FROM execution_entity WHERE \"workflowId\" = 'VolitexSyntheticProbe' AND status = 'success'")
test "$executions" -ge 1
"${compose[@]}" exec -T n8n-worker wget -qO- http://127.0.0.1:5678/healthz/readiness >/dev/null
# Persisted execution history must survive a graceful full stack restart.
"${compose[@]}" stop -t 30 n8n-worker n8n-main >/dev/null
"${compose[@]}" restart n8n-postgres n8n-valkey >/dev/null
"${compose[@]}" up -d n8n-main n8n-worker >/dev/null
ready=false
for attempt in $(seq 1 90); do
  if "${compose[@]}" exec -T n8n-main wget -qO- http://127.0.0.1:5678/healthz/readiness >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
test "$ready" = true
"${compose[@]}" exec -T n8n-main node -e "$probe" 60000
recovered=$("${compose[@]}" exec -T n8n-postgres psql -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -tAc "SELECT count(*) FROM execution_entity WHERE \"workflowId\" = 'VolitexSyntheticProbe' AND status = 'success'")
test "$recovered" -gt "$executions"
echo 'Execution persistence and graceful main/worker/PostgreSQL/Valkey restart verified.'
echo 'Pinned n8n main/worker, PostgreSQL/Valkey, queue-only execution and synthetic response checks passed.'
echo 'This does not verify Meta delivery, the production HMAC workflow, or an Inbox API reply.'
