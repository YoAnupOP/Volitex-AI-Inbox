# First-client production runbook

This is the runbook for the current independently maintained Volitex AI Inbox. It deliberately does **not** pull, merge, rebase, or cherry-pick Chatwoot upstream. A release is a commit from this repository, built as a Volitex-owned OCI image and deployed by immutable digest.

Use this only after the P0 branch containing this document has passed CI. Keep a change record with the Git commit, image digest, database backup ID, n8n image digest, and operator for every production change.

## 0. Non-negotiable go/no-go checks

Before creating a real client account, all of these must be true:

1. Meta has deleted/revoked the previously exposed App Secret. This is a Meta-console action; it is not a code change. Do not describe it as rotation if Meta offers only revocation.
2. The public Git history has been purged of the complete `.history/` directory (including its tracked environment snapshots) and checked without printing any secret. The safe procedure is in [Git history cleanup](#appendix-a-git-history-cleanup-for-the-exposed-secret).
3. The three `ACTIVE_RECORD_ENCRYPTION_*` values, `SECRET_KEY_BASE`, Meta configuration, WABA credentials, and n8n encryption key exist only in a password manager and Coolify secrets. They must never be in Git, workflow JSON, terminal history, or screenshots.
4. The managed PostgreSQL and managed Redis/Valkey provider are in the same region as the VPS, accept TLS connections from the VPS, and have independently tested provider recovery/PITR procedures.
5. The Postgres provider supports the extensions used by the current schema (`pgcrypto`, `pg_trgm`, `vector`, and `pg_stat_statements`). Check this before paying for the service; a plain managed Postgres plan that disallows `vector` will fail the first migration.
6. Object storage is provisioned. Set `ACTIVE_STORAGE_SERVICE=s3_compatible`; this production compose intentionally has no persistent local media volume. For a first client, this avoids treating VPS disk as the source of truth for client attachments.

If any item fails, do not configure a client WABA or send a client message.

## 1. Provision the services

### VPS and network

Provision a current Ubuntu LTS VPS in the same region as the managed database and Redis service. Start at 4 vCPU / 8 GB RAM / 80 GB SSD for one real client plus n8n queue worker; it is a starting point, not a capacity guarantee.

Allow inbound TCP only for SSH, 80, and 443. Restrict SSH to your administration IP or VPN. Do not expose 3000, 5432, 6379, or 5678 publicly. Configure provider firewalls so PostgreSQL and Redis accept only this VPS (or its private network) over TLS.

On the VPS, before installing application services:

```bash
sudo apt update && sudo apt -y full-upgrade
sudo adduser volitexops
sudo usermod -aG sudo volitexops
sudo timedatectl set-timezone Asia/Kolkata
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Use SSH keys, disable password SSH authentication after confirming the second administrative login, and enable unattended security updates. Install Coolify using its current official installer, then access Coolify only through its TLS-protected administrator URL.

### Managed PostgreSQL

Create two **separate databases and users** on the same managed cluster:

| Application | Database | Role | Access |
|---|---|---|---|
| Volitex AI Inbox | `volitex_inbox_production` | `volitex_inbox` | only this database |
| n8n | `volitex_n8n` | `volitex_n8n` | only this database |

Enable TLS, require `verify-full`, download the provider CA certificate, and store it as a Coolify secret-file mounted at `/run/secrets/managed-postgres-ca.pem`. Enable PITR and choose a retention period that matches client contracts; 14–30 days is a sensible first-client minimum. Take a named pre-onboarding backup before every schema/data migration.

The Inbox reads the TLS settings directly from [config/database.yml](../../config/database.yml): `POSTGRES_SSLMODE=verify-full` and `POSTGRES_SSLROOTCERT=/run/secrets/managed-postgres-ca.pem`.

### Managed Redis / Valkey

Use a dedicated managed Redis/Valkey instance for the Inbox and a second dedicated instance for n8n queue mode. Do **not** share one Redis database between Sidekiq/ActionCable and n8n/Bull queues: eviction policy, key lifetimes, queue recovery, upgrades, and a runaway bulk campaign are separate failure domains. If a provider makes a second instance temporarily impossible, use separate ACL users, separate logical databases, `noeviction`, and provider-confirmed key isolation—but treat that as a short-term exception, not the target architecture.

For the Inbox, use a `rediss://` URL, provider CA verification, and a restricted ACL user. Sidekiq and ActionCable use the same Inbox Redis instance because they are components of the same application and share its operational failure domain.

## 2. Build the Volitex image

The release workflow is [publish_volitex_image.yml](../../.github/workflows/publish_volitex_image.yml). It builds [docker/Dockerfile](../../docker/Dockerfile) and publishes a commit-tagged image. It writes the immutable digest to the GitHub Actions summary.

1. Merge the reviewed Volitex change into `master`; do not merge upstream Chatwoot.
2. Wait for `Publish Volitex Inbox image` and the CI workflow to pass.
3. Copy the exact `ghcr.io/yoanupop/volitex-ai-inbox@sha256:...` digest from the publish-job summary into the release record.
4. Ensure GHCR package visibility/authentication permits the Coolify server to pull it. Use a read-only package token stored in Coolify if the package is private.

Never deploy `chatwoot/chatwoot`, an image tag, or `latest`. [docker-compose.production.yaml](../../docker-compose.production.yaml) refuses to start unless `VOLITEX_IMAGE` is set to an image reference.

## 3. Deploy Volitex AI Inbox in Coolify

Create a Coolify **Docker Compose** application from this repository. Select [docker-compose.production.yaml](../../docker-compose.production.yaml), configure the domain `inbox.volitexai.tech`, target port `3000`, and enable Coolify-managed TLS. The compose exposes port 3000 only to the Docker network; Coolify's proxy is the public ingress.

Create the Coolify environment file named `.env` from this exact minimum. Replace every bracketed value in Coolify; do not create a populated repository file.

```dotenv
VOLITEX_IMAGE=ghcr.io/yoanupop/volitex-ai-inbox@sha256:<release-digest>
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker
FRONTEND_URL=https://inbox.volitexai.tech
FORCE_SSL=true
SECRET_KEY_BASE=<generated-with-bundle-exec-rails-secret>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<password-manager-value>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<password-manager-value>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<password-manager-value>

POSTGRES_HOST=<managed-postgres-hostname>
POSTGRES_PORT=5432
POSTGRES_DATABASE=volitex_inbox_production
POSTGRES_USERNAME=volitex_inbox
POSTGRES_PASSWORD=<managed-postgres-password>
POSTGRES_SSLMODE=verify-full
POSTGRES_SSLROOTCERT=/run/secrets/managed-postgres-ca.pem
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=8

REDIS_URL=rediss://<inbox-redis-user>:<inbox-redis-password>@<inbox-redis-host>:6379/0
REDIS_OPENSSL_VERIFY_MODE=peer

ACTIVE_STORAGE_SERVICE=s3_compatible
STORAGE_ACCESS_KEY_ID=<object-storage-access-key>
STORAGE_SECRET_ACCESS_KEY=<object-storage-secret>
STORAGE_REGION=<object-storage-region>
STORAGE_BUCKET_NAME=volitex-inbox-production
STORAGE_ENDPOINT=https://<object-storage-endpoint>
STORAGE_FORCE_PATH_STYLE=true

RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
ENABLE_ACCOUNT_SIGNUP=false
ENABLE_RACK_ATTACK=true
RACK_ATTACK_LIMIT=300
MAILER_SENDER_EMAIL=Volitex AI Inbox <accounts@volitexai.tech>
SMTP_ADDRESS=<smtp-host>
SMTP_PORT=587
SMTP_USERNAME=<smtp-user>
SMTP_PASSWORD=<smtp-password>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true

META_APP_SECRET=<current-nonexposed-meta-secret>
WHATSAPP_APP_ID=<meta-app-id>
WHATSAPP_API_VERSION=v24.0
FB_APP_ID=<meta-app-id>
FB_APP_SECRET=<current-nonexposed-meta-secret>
FB_VERIFY_TOKEN=<random-verification-token>
IG_VERIFY_TOKEN=<random-verification-token>
```

Add the provider CA as a Coolify secret file at `/run/secrets/managed-postgres-ca.pem`. Do not substitute `sslmode=disable` or a permissive certificate mode to make a connection work.

Before the first deploy, record the pre-migration managed-Postgres backup ID. Deploy the application. Coolify starts `rails` and `sidekiq`; the Rails entrypoint runs pending migrations. Verify:

```bash
curl --fail --silent --show-error https://inbox.volitexai.tech/api >/dev/null
```

Then inspect both Coolify service logs. There must be no migration error, encryption-key error, database TLS error, Redis TLS error, or repeated Sidekiq connection failure.

## 4. Deploy n8n in queue mode

Create a **second** Coolify Docker Compose application using [deployment/n8n-queue.compose.yaml](../../deployment/n8n-queue.compose.yaml). Configure its domain `automation.volitexai.tech` and target port `5678`. Use the companion [deployment/.env.n8n.example](../../deployment/.env.n8n.example) as the exact Coolify secret-file template.

Set `N8N_IMAGE` to one pinned digest and use the identical value for `n8n-main` and `n8n-worker`. Queue mode requires both services: the main process receives webhook/editor traffic and the worker processes automation/bulk/CRM jobs. Do not put bulk work on the main process.

Use the dedicated `volitex_n8n` Postgres database and dedicated n8n Redis/Valkey instance from step 1. Keep one worker at `--concurrency=5` for the first client. Raise that only after measuring API latency, provider rate limits, worker CPU/RAM, and queue age. Configure Coolify TLS/proxy exactly as it was for the Inbox, then confirm:

```bash
curl --fail --silent --show-error https://automation.volitexai.tech/healthz >/dev/null
```

Sign in once, set a strong owner password and MFA, create no public test workflows, and run `n8n audit` from the worker/container before client activation. n8n documents the audit command and reports credential, database, filesystem, node, and instance risks. [n8n security audit documentation](https://docs.n8n.io/hosting/securing/security-audit/)

## 5. Configure the first client channel and control plane

1. Create the client account and administrator in the Inbox. Keep `ENABLE_ACCOUNT_SIGNUP=false`.
2. Create the WhatsApp Cloud channel using the Inbox UI and manually enter the client-approved WABA token, phone number ID, and business account ID. The application now encrypts `api_key`, PINs, webhook verification tokens, and matching sensitive values in `channel_whatsapp.encrypted_provider_config`.
3. Set the callback URL in Meta to `https://inbox.volitexai.tech/webhooks/whatsapp/<phone-number>`. Verify Meta's challenge and then send an inbound test message. Every `whatsapp_cloud` request now requires `X-Hub-Signature-256`; do not add an unsigned exception for manual credentials.
4. Connect Instagram only through the approved OAuth flow and send an inbound/outbound test.
5. From the Inbox release container, provision a dedicated n8n machine identity once per customer account:

```bash
bundle exec rails 'volitex:create_n8n_agent_bot[<ACCOUNT_ID>,https://automation.volitexai.tech/webhook/volitex-inbox]'
```

Copy the resulting AgentBot token and signing secret only through the authenticated UI into n8n credentials. Attach the bot to the automation inbox. Never use an administrator or human-agent token in n8n.
6. In n8n, validate the Chatwoot webhook signature, retain the event delivery ID, and include a fresh `automation_delivery_id` on every `POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages` reply. A retry of the same ID is idempotent.
7. Turn AI mode on from the Inbox UI and verify that `automation_owner=n8n` and the dedicated bot is assigned. Have a human take over; verify the bot is unassigned and that a subsequent n8n reply is rejected with 422. The full contract is [n8n-control-plane.md](n8n-control-plane.md).

## 6. Backup, restore, and monitoring

### Backups

* PostgreSQL: managed provider PITR plus one daily logical backup retained outside the VPS. Encrypt backups and retain the matching Active Record encryption key set for their whole retention period.
* Object storage: enable versioning/lifecycle and provider replication or daily export. This replaces local media storage in this deployment.
* n8n: provider PITR for `volitex_n8n`, an encrypted export of workflows excluding credentials, and a securely retained `N8N_ENCRYPTION_KEY`.
* Configuration: maintain a password-manager record of all Coolify secrets and image digests; never back up secrets in the repository.

The P0 validation has already performed a full format dump and isolated restore of the test database, verifying both a known marker and schema migration `20260918000003`. Repeat this against the selected managed provider before first client activation and quarterly thereafter:

```bash
pg_dump --format=custom --no-owner --no-privileges \
  "host=<managed-host> port=5432 dbname=volitex_inbox_production user=volitex_inbox sslmode=verify-full sslrootcert=/run/secrets/managed-postgres-ca.pem" \
  --file=volitex-inbox-prechange.dump
createdb --host=<isolated-restore-host> --username=<restore-admin> volitex_inbox_restore_test
pg_restore --clean --if-exists --no-owner --dbname=volitex_inbox_restore_test volitex-inbox-prechange.dump
psql --host=<isolated-restore-host> --username=<restore-admin> --dbname=volitex_inbox_restore_test \
  -c 'SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;'
```

Destroy the isolated restore database after recording the evidence. Never restore a production dump over production to test it.

### Monitoring and alerts

Alert on HTTP availability/TLS expiry for both domains, Sidekiq queue latency/retries/dead jobs, n8n execution failures and queue age, PostgreSQL connections/CPU/storage/PITR health, Redis memory/evictions/connection errors, object-storage failures, and Meta webhook delivery errors. Send alerts to an operator channel that is checked outside business hours during the first client launch.

## 7. Mandatory smoke test and reboot test

Complete and record every item:

- [ ] Inbox and n8n TLS endpoints return healthy responses.
- [ ] Rails and Sidekiq connect using verified TLS to managed PostgreSQL and Redis.
- [ ] n8n main and worker both connect to its dedicated database/Redis; an intentionally slow bulk workflow does not delay a webhook test.
- [ ] A WhatsApp webhook with a valid signature is accepted; missing and invalid signatures are rejected.
- [ ] A duplicate Meta payload results in one inbound message.
- [ ] WhatsApp inbound, human outbound, n8n outbound, and human takeover all work.
- [ ] Instagram inbound/outbound works if enabled for the client.
- [ ] An n8n duplicate `automation_delivery_id` creates exactly one outgoing Inbox message.
- [ ] Temporarily make n8n's outgoing webhook fail; the conversation returns to human ownership rather than allowing competing replies.
- [ ] Upload/download a media attachment from the configured object store.
- [ ] Create an encrypted backup and restore it into an isolated database as described above.
- [ ] Reboot the VPS from the provider panel. Wait for Coolify, then verify both domains, Rails, Sidekiq, n8n main, and n8n worker recover without manual intervention.

Do not declare the client live until this checklist and the reboot test are recorded.

## 8. Volitex-only updates and rollback

1. Create a Volitex branch, make the smallest change, and run CI. Evaluate upstream only as security intelligence; do not sync it.
2. Publish the new Volitex image and record both the current and proposed digests.
3. Take and verify a managed-Postgres pre-change backup. Run the smoke tests in staging using the same external-service topology.
4. Change only `VOLITEX_IMAGE` in Coolify to the proposed **digest**, deploy, and run the smoke checklist.
5. For an application-only regression without a data migration, change `VOLITEX_IMAGE` back to the last known-good digest and redeploy.

Credential encryption is intentionally a compatibility boundary: after credentials have been moved to `encrypted_provider_config`, an image from before this P0 release cannot read them. Do not roll back across that boundary by merely changing the image digest. Use a forward fix, or restore the matching database backup **and** the matching encryption keys in an isolated recovery plan.

## Appendix A: Git history cleanup for the exposed secret

This purges the complete tracked `.history/` directory, including the exposed environment snapshots, without printing their content. Perform it from a clean machine/clone after all current code changes are committed and pushed to a non-destructive branch. This rewrites commit IDs, so notify every collaborator and protect the repository from old refs being pushed back. The backup itself still contains the exposed secret: keep it private and encrypted, and retain it only for the agreed recovery window.

```bash
git clone --mirror https://github.com/YoAnupOP/Volitex-AI-Inbox.git Volitex-AI-Inbox-pre-filter-backup.git
git -C Volitex-AI-Inbox-pre-filter-backup.git fsck --full
git clone --mirror https://github.com/YoAnupOP/Volitex-AI-Inbox.git Volitex-AI-Inbox-filter.git
git -C Volitex-AI-Inbox-filter.git filter-repo --force --path .history --invert-paths
git -C Volitex-AI-Inbox-filter.git log --all --name-only --pretty=format: | grep -E '^\.history/' && exit 1 || true
git -C Volitex-AI-Inbox-filter.git fsck --full
git -C Volitex-AI-Inbox-filter.git remote add origin https://github.com/YoAnupOP/Volitex-AI-Inbox.git
git -C Volitex-AI-Inbox-filter.git push --force --mirror origin
```

Before the last command, verify the backup exists, `fsck` passes, and the repository owner accepts the force-push impact. Afterward, delete GitHub forks/caches/releases that still contain the old objects where possible, ask collaborators to reclone, and enable secret scanning/push protection. [`.gitignore`](../../.gitignore) now ignores `.history/`; do not use editor local-history extensions inside this repository.
