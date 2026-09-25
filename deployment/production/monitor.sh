#!/usr/bin/env bash

set -Eeuo pipefail

: "${INBOX_HEALTH_URL:?Set INBOX_HEALTH_URL, for example https://inbox.volitexai.tech/health}"
: "${N8N_HEALTH_URL:?Set N8N_HEALTH_URL, for example https://automation.volitexai.tech/healthz}"
: "${ALERT_WEBHOOK_URL:?Set ALERT_WEBHOOK_URL to an operator alert webhook}"

command -v curl >/dev/null || { echo 'curl is required' >&2; exit 1; }
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 1; }

failures=()

check_http() {
  local name="$1"
  local url="$2"

  if ! curl --fail --silent --show-error --max-time "${HTTP_TIMEOUT_SECONDS:-10}" "$url" >/dev/null; then
    failures+=("${name} health check failed: ${url}")
  fi
}

check_http inbox "$INBOX_HEALTH_URL"
check_http n8n "$N8N_HEALTH_URL"

check_postgres() {
  local name="$1"
  local database_url="$2"
  local active_connections
  local max_connections

  if ! active_connections="$(psql "$database_url" -Atqc 'SELECT count(*) FROM pg_stat_activity;')" || \
     ! max_connections="$(psql "$database_url" -Atqc 'SHOW max_connections;')"; then
    failures+=("${name} PostgreSQL check failed")
    return
  fi

  if [[ "$active_connections" -ge "$((max_connections * 85 / 100))" ]]; then
    failures+=("${name} PostgreSQL connections are ${active_connections}/${max_connections}")
  fi
}

check_redis() {
  local name="$1"
  local redis_url="$2"
  local info
  local evicted_keys

  if ! info="$(redis-cli --no-auth-warning -u "$redis_url" INFO memory,stats)"; then
    failures+=("${name} Redis/Valkey check failed")
    return
  fi

  evicted_keys="$(printf '%s\n' "$info" | awk -F: '$1 == "evicted_keys" { print $2 }' | tr -d '\r')"
  if [[ "${evicted_keys:-0}" -gt 0 ]]; then
    failures+=("${name} Redis/Valkey has evicted ${evicted_keys} keys")
  fi
}

if [[ -n "${VOLITEX_DATABASE_URL:-}" || -n "${N8N_DATABASE_URL:-}" ]]; then
  command -v psql >/dev/null || failures+=('psql is required when database URLs are configured')
  [[ -n "${VOLITEX_DATABASE_URL:-}" ]] && check_postgres volitex "$VOLITEX_DATABASE_URL"
  [[ -n "${N8N_DATABASE_URL:-}" ]] && check_postgres n8n "$N8N_DATABASE_URL"
fi

if [[ -n "${VOLITEX_REDIS_URL:-}" || -n "${N8N_REDIS_URL:-}" ]]; then
  command -v redis-cli >/dev/null || failures+=('redis-cli is required when Redis URLs are configured')
  [[ -n "${VOLITEX_REDIS_URL:-}" ]] && check_redis volitex "$VOLITEX_REDIS_URL"
  [[ -n "${N8N_REDIS_URL:-}" ]] && check_redis n8n "$N8N_REDIS_URL"
fi

disk_path="${MONITOR_DISK_PATH:-/}"
disk_used="$(df -P "$disk_path" | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"
if [[ -z "$disk_used" || "$disk_used" -ge "${DISK_USED_ALERT_PERCENT:-85}" ]]; then
  failures+=("disk usage is ${disk_used:-unknown}% on ${disk_path}")
fi

if ((${#failures[@]} > 0)); then
  message="Volitex production monitor alert ($(hostname))\n- $(printf '%s\n- ' "${failures[@]}")"
  curl --fail --silent --show-error --max-time 10 \
    -H 'Content-Type: application/json' \
    --data "$(printf '%s' "$message" | jq -Rs '{text: .}')" \
    "$ALERT_WEBHOOK_URL" >/dev/null
  printf '%s\n' "${failures[@]}" >&2
  exit 1
fi

echo "healthy: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
