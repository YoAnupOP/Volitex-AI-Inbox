#!/usr/bin/env bash
set -euo pipefail
entrypoint="$(pwd)/docker/entrypoints/rails.sh"
scratch=$(mktemp -d)
candidate_original_path=$PATH
trap 'PATH="$candidate_original_path" command rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/docker/entrypoints/helpers"
cat > "$scratch/bin/bundle" <<'SH'
#!/bin/sh
echo "$*" >> "$CANDIDATE_BUNDLE_TRACE"
if [ "$*" = check ] && [ "${CANDIDATE_CHECK_FAIL:-0}" = 1 ]; then exit 7; fi
SH
cat > "$scratch/bin/pg_isready" <<'SH'
#!/bin/sh
exit 0
SH
cat > "$scratch/bin/rm" <<'SH'
#!/bin/sh
# Do not touch /app during the mocked entrypoint check.
exit 0
SH
cat > "$scratch/docker/entrypoints/helpers/pg_database_url.rb" <<'SH'
#!/bin/sh
echo 'export POSTGRES_PORT=5432'
SH
chmod +x "$scratch/bin/"* "$scratch/docker/entrypoints/helpers/pg_database_url.rb"
export PATH="$scratch/bin:$PATH"
export CANDIDATE_BUNDLE_TRACE="$scratch/bundle.log"
export POSTGRES_HOST=disposable POSTGRES_USERNAME=disposable
cd "$scratch"
RAILS_ENV=production sh "$entrypoint" true > /dev/null
test "$(cat "$CANDIDATE_BUNDLE_TRACE")" = check
: > "$CANDIDATE_BUNDLE_TRACE"
RAILS_ENV=development sh "$entrypoint" true > /dev/null
test "$(cat "$CANDIDATE_BUNDLE_TRACE")" = install
if RAILS_ENV=production CANDIDATE_CHECK_FAIL=1 sh "$entrypoint" true > /dev/null; then
  echo 'Missing production dependencies must fail startup' >&2
  exit 1
fi
echo 'Three mocked entrypoint checks passed.'
