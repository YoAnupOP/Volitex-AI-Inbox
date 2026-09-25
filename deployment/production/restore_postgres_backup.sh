#!/usr/bin/env bash

set -Eeuo pipefail

: "${RESTORE_DATABASE_URL:?Set RESTORE_DATABASE_URL to an isolated PostgreSQL database URL}"
: "${BACKUP_S3_URI:?Set BACKUP_S3_URI to the off-server S3-compatible prefix}"
: "${AGE_IDENTITY:?Set AGE_IDENTITY to the backup encryption private-key file}"

backup_object="${1:?Usage: restore_postgres_backup.sh <s3-object-key> [expected-schema-version]}"
expected_schema_version="${2:-}"

command -v pg_restore >/dev/null || { echo 'pg_restore is required' >&2; exit 1; }
command -v psql >/dev/null || { echo 'psql is required' >&2; exit 1; }
command -v aws >/dev/null || { echo 'aws CLI is required' >&2; exit 1; }
command -v age >/dev/null || { echo 'age is required' >&2; exit 1; }

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/volitex-restore.XXXXXX")"
encrypted_file="$work_dir/restore.dump.age"
dump_file="$work_dir/restore.dump"
trap 'rm -rf -- "$work_dir"' EXIT

aws_args=()
[[ -n "${AWS_ENDPOINT_URL:-}" ]] && aws_args+=(--endpoint-url "$AWS_ENDPOINT_URL")
aws "${aws_args[@]}" s3 cp "${BACKUP_S3_URI%/}/${backup_object}" "$encrypted_file"
age --decrypt --identity "$AGE_IDENTITY" --output "$dump_file" "$encrypted_file"
pg_restore --list "$dump_file" >/dev/null
pg_restore --clean --if-exists --no-owner --no-privileges --dbname "$RESTORE_DATABASE_URL" "$dump_file"

schema_version="$(psql "$RESTORE_DATABASE_URL" -Atc 'SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;')"
if [[ -n "$expected_schema_version" && "$schema_version" != "$expected_schema_version" ]]; then
  echo "restored schema ${schema_version}, expected ${expected_schema_version}" >&2
  exit 1
fi

echo "restore verified: schema ${schema_version}"
