# First-client production runbook

This is the runbook for the current independently maintained Volitex AI Inbox. It deliberately does **not** pull, merge, rebase, or cherry-pick Chatwoot upstream. A release is a commit from this repository, built as a Volitex-owned OCI image and deployed by immutable digest.

Use this only after the P0 branch containing this document has passed CI. Keep a change record with the Git commit, image digest, database backup ID, n8n image digest, and operator for every production change.

## 0. Non-negotiable go/no-go checks

Before creating a real client account, all of these must be true:

1. Meta has deleted/revoked the previously exposed App Secret. This is a Meta-console action; it is not a code change. Do not describe it as rotation if Meta offers only revocation.
2. The public Git history has been purged of the complete `.history/` directory (including its tracked environment snapshots) and checked without printing any secret. The safe procedure is in [Git history cleanup](#appendix-a-git-history-cleanup-for-the-exposed-secret).
3. The three `ACTIVE_RECORD_ENCRYPTION_*` values, `SECRET_KEY_BASE`, Meta configuration, WABA credentials, and n8n encryption key exist only in a password manager and Coolify secrets. They must never be in Git, workflow JSON, terminal history, or screenshots.
4. The Hostinger KVM 4 VPS is the first-client infrastructure boundary: Coolify, Volitex, n8n, their separate PostgreSQL and Redis/Valkey services, and their persistent volumes run on it. The only public application entry points are Coolify HTTPS routes.
5. The self-hosted Volitex PostgreSQL image and configuration provide `pgcrypto`, `pg_trgm`, `vector`, and `pg_stat_statements`. A plain PostgreSQL image without `vector`, or one without the required extension configuration, will fail the first migration.
6. Object storage is provisioned. Set `ACTIVE_STORAGE_SERVICE=s3_compatible`; this production compose intentionally has no persistent local media volume. For a first client, this avoids treating VPS disk as the source of truth for client attachments.

If any item fails, do not configure a client WABA or send a client message.

## 1. Provision the services

### VPS and network

Provision the Hostinger KVM 4: Ubuntu 24.04 LTS, 4 vCPU, 16 GB RAM, and 200 GB NVMe. This single VPS hosts Coolify, Volitex, n8n, two PostgreSQL services, and two Redis/Valkey boundaries. It is a starting point, not a capacity guarantee; CPU, RAM, disk IOPS, and disk capacity are shared across the complete stack.

Allow inbound TCP only for SSH, 80, and 443. Restrict SSH to your administration IP or VPN. Do not expose 3000, 5432, 6379, or 5678 publicly. PostgreSQL, Redis/Valkey, and the n8n worker remain private Docker/Coolify services; only Coolify's proxy routes `inbox.volitexai.tech` and `automation.volitexai.tech` to their respective main application containers.

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

### Self-hosted PostgreSQL

Provision two separate self-hosted PostgreSQL services with separate persistent volumes, databases, and users. Do not put n8n tables in the Volitex database or share a database role:

| Application | Database | Role | Access |
|---|---|---|---|
| Volitex AI Inbox | `volitex_inbox_production` | `volitex_inbox` | only this database |
| n8n | `volitex_n8n` | `volitex_n8n` | only this database |

Use an immutable Volitex PostgreSQL image that includes the required extensions listed in section 0 and configure `pg_stat_statements` before the first migration. The n8n stack provisions its own PostgreSQL service from `deployment/n8n-queue.compose.yaml`. Neither database has a published port. Container-to-container connections remain on the private Coolify/Docker network; do not add TLS to that private path merely to imitate a managed-service topology.

Take an encrypted, off-server logical backup before every schema/data migration. A persistent volume protects against container recreation and reboot; it is not a backup and does not protect against VPS loss, operator error, or ransomware.

### Self-hosted Redis / Valkey

Provision a dedicated self-hosted Redis/Valkey boundary with a persistent volume and generated password for Volitex. The n8n Compose stack provisions a second dedicated Valkey service with a different password, named volume, and `volitex:n8n` Bull prefix. Do **not** share a Redis database, password, namespace, or container between Sidekiq/ActionCable and n8n/Bull queues.

Do not publish either Redis/Valkey port. Sidekiq and ActionCable use the Volitex Redis/Valkey service because they are components of the same application and share its operational failure domain. Apply `noeviction` or an explicitly documented eviction policy sized for the available VPS memory; an eviction policy is an operational decision, not a default to leave implicit.

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

POSTGRES_HOST=<private-volitex-postgres-service-hostname>
POSTGRES_PORT=5432
POSTGRES_DATABASE=volitex_inbox_production
POSTGRES_USERNAME=volitex_inbox
POSTGRES_PASSWORD=<generated-volitex-postgres-password>
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=8

REDIS_URL=redis://:<generated-volitex-valkey-password>@<private-volitex-valkey-service-hostname>:6379/0

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

Provision the private Volitex PostgreSQL and Redis/Valkey services before this application, with their own Coolify-managed volumes and secrets. Do not attach the Inbox to the n8n database, n8n Valkey service, or n8n credentials. Before the first deploy, record the encrypted off-server pre-migration backup identifier. Deploy the application. Coolify starts `rails` and `sidekiq`; the Rails entrypoint runs pending migrations. Verify:

```bash
curl --fail --silent --show-error https://inbox.volitexai.tech/api >/dev/null
```

Then inspect both Coolify service logs. There must be no migration error, encryption-key error, database TLS error, Redis TLS error, or repeated Sidekiq connection failure.

## 4. Deploy n8n in queue mode

Create a **second** Coolify Docker Compose application using [deployment/n8n-queue.compose.yaml](../../deployment/n8n-queue.compose.yaml). Configure `automation.volitexai.tech:5678` on **n8n-main only**. The n8n worker, PostgreSQL, and Valkey services have no public domain or published ports.

Copy the keys from [deployment/.env.n8n.example](../../deployment/.env.n8n.example) into Coolify's Environment Variables view and replace every placeholder there. It is a sanitized schema, not a repository secret-file or a runtime `.env.n8n` dependency. The reviewed baseline pins n8n 2.40.3, PostgreSQL 17.11, and Valkey 8.1 by immutable digest; record those exact versions and digests in the release record and re-verify the n8n environment contract before changing them.

The Compose stack creates the dedicated self-hosted `volitex_n8n` PostgreSQL database and its dedicated Valkey queue with separate credentials and persistent volumes. Both `n8n-main` and `n8n-worker` receive the same `N8N_ENCRYPTION_KEY`, database configuration, queue configuration, and `EXECUTIONS_MODE=queue`; main alone receives public editor/webhook traffic. Manual executions are offloaded to the worker. Keep one worker at `N8N_WORKER_CONCURRENCY=5` for the first client. Raise it only after measuring API latency, provider rate limits, worker CPU/RAM, Redis memory, and queue age.

Coolify terminates TLS. `N8N_EDITOR_BASE_URL` and `N8N_WEBHOOK_URL` must be `https://automation.volitexai.tech`, and `N8N_PROXY_HOPS=1` is correct only while Coolify is the single trusted proxy. The `n8n_data` volume belongs only to main; n8n PostgreSQL persists workflows and credentials for both processes, while workers receive the same explicit encryption key. The `n8n_data`, `n8n_postgres_data`, and `n8n_valkey_data` volumes must remain attached across container replacement and VPS reboot. They are not backups.

After deployment, confirm the public main readiness endpoint and the private worker readiness healthcheck:

```bash
curl --fail --silent --show-error https://automation.volitexai.tech/healthz >/dev/null
```

Sign in once, set a strong owner password and MFA, configure the SMTP-backed recovery address, create no public test workflows, and run `n8n audit` from the worker/container before client activation. n8n documents the audit command and reports credential, database, filesystem, node, and instance risks. [n8n security audit documentation](https://docs.n8n.io/hosting/securing/security-audit/)

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
6. In n8n, validate the exact Inbox webhook signature and retain the delivery ID before processing. Include a fresh `automation_delivery_id` on every `POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages` reply. A retry of the same ID is idempotent. The exact request and failure contract is [n8n-control-plane.md](n8n-control-plane.md).
7. Turn AI mode on from the Inbox UI and verify that `automation_owner=n8n` and the dedicated bot is assigned. Have a human take over; verify the bot is unassigned and that a subsequent n8n reply is rejected with 422. The full contract is [n8n-control-plane.md](n8n-control-plane.md).

## 6. Backup, restore, and monitoring

### Backups

* PostgreSQL: take encrypted logical backups of both self-hosted PostgreSQL services daily and before every migration, then transfer and verify them off-server. Retain the matching Active Record encryption key set and `N8N_ENCRYPTION_KEY` for the full backup-retention period. VPS snapshots may supplement these backups but do not replace tested logical restore.
* Object storage: enable versioning/lifecycle and provider replication or daily export. This replaces local media storage in this deployment.
* n8n: back up `volitex_n8n`, retain an encrypted export of workflows excluding credentials, retain `N8N_ENCRYPTION_KEY`, and record the n8n, PostgreSQL, and Valkey image digests. The `n8n_data` volume is persistent operational state, not a substitute for the database backup.
* Configuration: maintain a password-manager record of all Coolify secrets and image digests; never back up secrets in the repository.

The P0 validation has already performed a full format dump and isolated restore of the test database, verifying both a known marker and schema migration `20260918000003`. Repeat this from the self-hosted Volitex PostgreSQL service into an isolated restore target before first client activation and quarterly thereafter:

```bash
pg_dump --format=custom --no-owner --no-privileges \
  "host=<private-volitex-postgres-service-hostname> port=5432 dbname=volitex_inbox_production user=volitex_inbox" \
  --file=volitex-inbox-prechange.dump
createdb --host=<isolated-restore-host> --username=<restore-admin> volitex_inbox_restore_test
pg_restore --clean --if-exists --no-owner --dbname=volitex_inbox_restore_test volitex-inbox-prechange.dump
psql --host=<isolated-restore-host> --username=<restore-admin> --dbname=volitex_inbox_restore_test \
  -c 'SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;'
```

Destroy the isolated restore database after recording the evidence. Never restore a production dump over production to test it.

### Monitoring and alerts

Alert on HTTP availability/TLS expiry for both domains, Sidekiq queue latency/retries/dead jobs, n8n execution failures and queue age, both PostgreSQL services' connections/storage/backup freshness, both Redis/Valkey services' memory/evictions/connection errors, VPS CPU/RAM/NVMe capacity and IOPS, object-storage failures, and Meta webhook delivery errors. Send alerts to an operator channel that is checked outside business hours during the first client launch.

## 7. Mandatory smoke test and reboot test

Complete and record every item:

- [ ] Inbox and n8n TLS endpoints return healthy responses.
- [ ] Rails and Sidekiq connect only to their private, dedicated self-hosted PostgreSQL and Redis/Valkey services.
- [ ] n8n main and worker both connect to its dedicated database/Redis; an intentionally slow bulk workflow does not delay a webhook test.
- [ ] A WhatsApp webhook with a valid signature is accepted; missing and invalid signatures are rejected.
- [ ] A duplicate Meta payload results in one inbound message.
- [ ] WhatsApp inbound, human outbound, n8n outbound, and human takeover all work.
- [ ] Instagram inbound/outbound works if enabled for the client.
- [ ] An n8n duplicate `automation_delivery_id` creates exactly one outgoing Inbox message.
- [ ] Force the Inbox-to-n8n AgentBot webhook to time out or finally fail; the conversation returns to human ownership rather than allowing competing replies.
- [ ] Force n8n's outgoing Inbox API request to fail; verify bounded workflow retry, alerting, and `automation_delivery_id` idempotency. This is not the automatic human-handoff signal.
- [ ] Upload/download a media attachment from the configured object store.
- [ ] Create an encrypted backup and restore it into an isolated database as described above.
- [ ] Reboot the VPS from the provider panel. Wait for Coolify, then verify both domains, Rails, Sidekiq, n8n main, and n8n worker recover without manual intervention.

Do not declare the client live until this checklist and the reboot test are recorded.

## 8. Volitex-only updates and rollback

1. Create a Volitex branch, make the smallest change, and run CI. Evaluate upstream only as security intelligence; do not sync it.
2. Publish the new Volitex image and record both the current and proposed digests.
3. Take and verify encrypted off-server pre-change backups of the self-hosted Volitex and n8n PostgreSQL services. Run the smoke tests in staging using the same single-VPS service topology.
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
