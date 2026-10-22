#!/usr/bin/env bash
# Disposable verification only. Never pass a production environment file.
set -euo pipefail
image=${1:?candidate image required}
commit=${2:?commit required}
app_postgres_image=${3:?verified Inbox pgvector image required}
app_valkey_image=${4:?verified Inbox Valkey image required}
prefix="volitex-verify-${GITHUB_RUN_ID:-$$}"
scratch=$(mktemp -d)
cleanup() {
  docker rm -f "$prefix-web" "$prefix-worker" "$prefix-campaign-worker" "$prefix-db" "$prefix-redis" >/dev/null 2>&1 || true
  docker network rm "$prefix" >/dev/null 2>&1 || true
  rm -rf "$scratch"
}
trap cleanup EXIT
umask 077
python3 - "$scratch/.env" "$prefix" <<'PY'
import secrets
import sys
path, prefix = sys.argv[1:]
values = {
    'RAILS_ENV': 'production', 'NODE_ENV': 'production', 'INSTALLATION_ENV': 'docker',
    'FRONTEND_URL': 'http://127.0.0.1:3000', 'FORCE_SSL': 'false',
    'SECRET_KEY_BASE': secrets.token_hex(64),
    'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY': secrets.token_hex(32),
    'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY': secrets.token_hex(32),
    'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT': secrets.token_hex(32),
    'POSTGRES_HOST': prefix + '-db', 'POSTGRES_DATABASE': 'candidate',
    'POSTGRES_USERNAME': 'postgres', 'POSTGRES_PASSWORD': secrets.token_hex(24),
    'REDIS_URL': 'redis://' + prefix + '-redis:6379/0',
    'RAILS_LOG_TO_STDOUT': 'true', 'ACTIVE_STORAGE_SERVICE': 'local',
    'ENABLE_ACCOUNT_SIGNUP': 'false', 'SIDEKIQ_CONCURRENCY': '2',
    'VOLITEX_AUTOMATION_NETWORK': prefix + '-automation',
}
with open(path, 'w') as stream:
    stream.write(''.join(f'{key}={value}\n' for key, value in values.items()))
PY
VOLITEX_IMAGE="$image" docker compose --project-directory "$scratch" --env-file "$scratch/.env" -f docker-compose.production.yaml config --quiet
# This image is local to the disposable runner; no registry push occurs.
test "$(docker run --rm "$image" cat /app/.git_sha)" = "$commit"
docker run --rm "$image" sh -ec 'test ! -d /app/node_modules; test ! -d /usr/local/lib/node_modules; test ! -d /app/tests; ! find /gems -type d -name node_modules -print -quit | grep -q .; test -f /app/public/vite/.vite/manifest.json; ! find /gems/ruby/3.4.0/gems -maxdepth 1 -name "rspec-*" | grep -q .'
docker run --rm "$image" ruby -rzlib -rrubygems -e 'raise "Vulnerable zlib runtime" if Gem::Version.new(Zlib::VERSION) < Gem::Version.new("3.2.3"); puts "Ruby #{RUBY_VERSION}, zlib #{Zlib::VERSION} verified"'
docker network create "$prefix" >/dev/null
if docker volume inspect "$prefix-storage" >/dev/null 2>&1; then
  echo 'Verification storage volume already exists; refusing to reuse data.' >&2
  exit 1
fi
docker volume create "$prefix-storage" >/dev/null
docker run -d --name "$prefix-db" --network "$prefix" --env-file "$scratch/.env" "$app_postgres_image" >/dev/null
docker run -d --name "$prefix-redis" --network "$prefix" "$app_valkey_image" >/dev/null
for attempt in $(seq 1 60); do
  if docker exec "$prefix-db" pg_isready -U postgres >/dev/null 2>&1; then break; fi
  sleep 2
done
docker exec "$prefix-db" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS pg_trgm; CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'
test "$(docker exec "$prefix-db" psql -U postgres -d postgres -tAc "SELECT '[1,2]'::vector <-> '[1,2]'::vector")" = 0
docker exec "$prefix-db" psql -U postgres -d postgres -tAc 'SHOW shared_preload_libraries' | grep -q pg_stat_statements

docker run --rm --network "$prefix" --env-file "$scratch/.env" --entrypoint docker/entrypoints/rails.sh "$image" bundle exec rails db:chatwoot_prepare
docker run -d --name "$prefix-web" --network "$prefix" --volume "$prefix-storage:/app/storage" --env-file "$scratch/.env" --entrypoint docker/entrypoints/rails.sh "$image" bundle exec rails s -p 3000 -b 0.0.0.0 >/dev/null
docker run -d --name "$prefix-worker" --env SIDEKIQ_HEALTH_QUEUE=critical --network "$prefix" --volume "$prefix-storage:/app/storage" --env-file "$scratch/.env" "$image" bundle exec sidekiq -C config/sidekiq.yml >/dev/null
docker run -d --name "$prefix-campaign-worker" --env SIDEKIQ_CONCURRENCY=2 --env SIDEKIQ_DB_POOL=2 --network "$prefix" --volume "$prefix-storage:/app/storage" --env-file "$scratch/.env" "$image" bundle exec sidekiq -C config/sidekiq_campaigns.yml >/dev/null
ready=false
for attempt in $(seq 1 90); do
  if docker exec "$prefix-web" curl --fail --silent http://127.0.0.1:3000/health > "$scratch/health.json"; then ready=true; break; fi
  sleep 2
done
test "$ready" = true
python3 - "$scratch/health.json" <<'PY'
import json
import sys
assert json.load(open(sys.argv[1]))['status'] == 'woot'
PY
docker exec "$prefix-web" curl --fail --silent http://127.0.0.1:3000/api >/dev/null
docker exec "$prefix-web" curl --fail --silent http://127.0.0.1:3000/app/login >/dev/null
docker exec "$prefix-web" bundle exec rails runner 'require "sidekiq/api"; raise unless ActiveRecord::Base.connection.active?; raise unless Redis.new(url: ENV.fetch("REDIS_URL")).ping == "PONG"; raise unless ActiveRecord::Base.connection.table_exists?(:quick_menus); raise unless Sidekiq::ProcessSet.new.any? { |process| process["queues"].include?("campaigns") }; raise unless ActiveRecord::Base.connection.table_exists?(:campaign_recipients); puts "Database, Redis, Quick Menus schema and Sidekiq verified"'
docker exec "$prefix-web" sh -ec 'printf verified > /app/storage/.volitex-verification'
docker run --rm --volume "$prefix-storage:/app/storage:ro" "$image" sh -ec 'test "$(cat /app/storage/.volitex-verification)" = verified'
docker exec "$prefix-db" pg_dump -U postgres -d candidate --format custom > "$scratch/database.dump"
docker exec "$prefix-db" createdb -U postgres candidate_restore
docker exec -i "$prefix-db" pg_restore -U postgres -d candidate_restore --exit-on-error < "$scratch/database.dump"
test "$(docker exec "$prefix-db" psql -U postgres -d candidate_restore -tAc "SELECT count(*) FROM information_schema.tables WHERE table_name = 'quick_menus'")" = 1
test "$(docker exec "$prefix-db" psql -U postgres -d candidate_restore -tAc "SELECT count(*) FROM information_schema.tables WHERE table_name IN ('campaign_recipients', 'campaign_dispatch_slots')")" = 2
echo 'Shared attachment storage and disposable PostgreSQL dump/restore verified.'
docker restart "$prefix-web" "$prefix-worker" "$prefix-campaign-worker" >/dev/null
ready=false
for attempt in $(seq 1 90); do
  if docker exec "$prefix-web" curl --fail --silent http://127.0.0.1:3000/health >/dev/null; then ready=true; break; fi
  sleep 2
done
test "$ready" = true
docker exec "$prefix-web" sh -ec 'test "$(cat /app/storage/.volitex-verification)" = verified'
docker exec "$prefix-web" curl --fail --silent http://127.0.0.1:3000/health >/dev/null
test "$(docker inspect --format '{{.State.Running}}' "$prefix-worker")" = true
test "$(docker inspect --format '{{.State.Running}}' "$prefix-campaign-worker")" = true
docker exec "$prefix-worker" bundle exec ruby script/production/campaign_worker_health.rb
docker exec "$prefix-campaign-worker" bundle exec ruby script/production/campaign_worker_health.rb
docker stop --time 30 "$prefix-web" "$prefix-worker" "$prefix-campaign-worker" >/dev/null
echo 'Candidate migration, web/worker boot, connectivity, restart and graceful stop checks passed.'
