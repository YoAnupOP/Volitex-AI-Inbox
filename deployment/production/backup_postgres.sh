#!/usr/bin/env bash

set -Eeuo pipefail

: "${VOLITEX_DATABASE_URL:?Set VOLITEX_DATABASE_URL to the Volitex PostgreSQL connection URL}"
: "${N8N_DATABASE_URL:?Set N8N_DATABASE_URL to the n8n PostgreSQL connection URL}"
: "${BACKUP_S3_URI:?Set BACKUP_S3_URI to an off-server S3-compatible prefix}"
: "${AGE_RECIPIENT:?Set AGE_RECIPIENT to the backup encryption public key}"
: "${AGE_IDENTITY:?Set AGE_IDENTITY to the backup encryption private-key file}"

command -v pg_dump >/dev/null || { echo 'pg_dump is required' >&2; exit 1; }
command -v pg_restore >/dev/null || { echo 'pg_restore is required' >&2; exit 1; }
command -v aws >/dev/null || { echo 'aws CLI is required' >&2; exit 1; }
command -v age >/dev/null || { echo 'age is required' >&2; exit 1; }

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_parent="${BACKUP_WORK_DIR:-${TMPDIR:-/tmp}}"
work_dir="$(mktemp -d "${backup_parent%/}/volitex-backup.XXXXXX")"

cleanup() {
  rm -rf -- "$work_dir"
}
trap cleanup EXIT

aws_s3() {
  local aws_args=()
  [[ -n "${AWS_ENDPOINT_URL:-}" ]] && aws_args+=(--endpoint-url "$AWS_ENDPOINT_URL")
  aws "${aws_args[@]}" s3 cp "$@"
}

dump_database() {
  local name="$1"
  local database_url="$2"
  local dump_file="$work_dir/${name}-${timestamp}.dump"
  local encrypted_file="$work_dir/${name}-${timestamp}.dump.age"
  local object_uri="${BACKUP_S3_URI%/}/${timestamp}/${name}.dump.age"
  local verify_encrypted_file="$work_dir/${name}-${timestamp}.verify.dump.age"
  local verify_file="$work_dir/${name}-${timestamp}.verify.dump"

  pg_dump --format=custom --no-owner --no-privileges "$database_url" --file "$dump_file"
  pg_restore --list "$dump_file" >/dev/null
  age --encrypt --recipient "$AGE_RECIPIENT" --output "$encrypted_file" "$dump_file"
  aws_s3 "$encrypted_file" "$object_uri"
  aws_s3 "$object_uri" "$verify_encrypted_file"
  age --decrypt --identity "$AGE_IDENTITY" --output "$verify_file" "$verify_encrypted_file"
  pg_restore --list "$verify_file" >/dev/null

  echo "verified ${object_uri}"
}

dump_database volitex "$VOLITEX_DATABASE_URL"
dump_database n8n "$N8N_DATABASE_URL"
