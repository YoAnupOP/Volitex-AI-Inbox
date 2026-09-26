#!/usr/bin/env bash

set -Eeuo pipefail

: "${VOLITEX_DATABASE_URL:?Set VOLITEX_DATABASE_URL to the isolated Volitex PostgreSQL URL}"

command -v psql >/dev/null || { echo 'psql is required' >&2; exit 1; }

required_extensions=(pgcrypto pg_trgm vector pg_stat_statements)
for extension in "${required_extensions[@]}"; do
  if ! psql "$VOLITEX_DATABASE_URL" -Atqc \
    "SELECT 1 FROM pg_available_extensions WHERE name = '${extension}' LIMIT 1;" | grep -qx '1'; then
    echo "PostgreSQL extension is unavailable: ${extension}" >&2
    exit 1
  fi
done

preloaded_libraries="$(psql "$VOLITEX_DATABASE_URL" -Atqc "SELECT current_setting('shared_preload_libraries');" | tr -d ' ')"
if [[ ",${preloaded_libraries}," != *,pg_stat_statements,* ]]; then
  echo 'pg_stat_statements is not present in shared_preload_libraries' >&2
  exit 1
fi

echo "PostgreSQL preflight passed: ${preloaded_libraries:-no shared preload libraries}"
