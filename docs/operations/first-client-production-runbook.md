# Volitex AI Inbox — First-client production operations runbook

## Current verified release — October 20, 2026

The deployment baseline is source `1ea83b0832faeafbbf867496b69f75f6a992ffb8` on `master`. All four exact-source gates completed successfully: [candidate and n8n recovery/security](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39422361108), [migration compatibility](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39422360732), [campaign lifecycle](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39422360698), and [full CE suite, 20/20 jobs](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39422361168). [Publication run 39424886778](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39424886778) published all four images in the table below. Their embedded source markers match this commit. This includes the private AgentBot transport, credential/idempotency controls and maintained n8n stack.

**Release status:** exact-source CI verified and published for the private, operator-managed HTTP/JSON n8n profile. The deployment kit is prepared; live deployment status is **NOT_DEPLOYED**. Actual KVM networking/TLS, private-editor login, off-host backups, restore/reboot/alerts, measured capacity and client acceptance must pass before client traffic. A successful image publication does not perform these steps.

**Security scope:** n8n has zero unresolved Critical/High findings after two exact-source-verified backports. The raw scan retains one High, eleven Medium and one Low finding; the verified braces High and stream-json Medium fixes are recorded separately. Ten unresolved Medium and one Low remain documented under the restricted capability profile. The maintained n8n PostgreSQL and Valkey publication scans have zero findings. This is not a vulnerability-free claim. See the [security remediation record](n8n-security-remediation-2026-10-20.md) and [runtime maintenance process](../../deployment/n8n/hardened/README.md).

**Client scope:** appointment booking with calendar/CRM integration; providers are chosen per client. `deployment/n8n/inbox-reply.workflow.json` is a fixed-reply integration test, not an accepted booking workflow. Configure and accept each client's workflow during onboarding using the [capability and booking acceptance checklist](n8n-capabilities-2026-10-19.md).

This is the current operating procedure for the planned shared Hostinger KVM 4 deployment. Older dated audit/publication reports are historical evidence; their image pins, source-only verdicts and public n8n instructions do not override this release or the actual Compose files.

## Operating position

Volitex AI Inbox is a shared multi-tenant service:

```text
Meta WhatsApp + Instagram
        |
        v
Volitex AI Inbox (Rails + Sidekiq)
        |
        v
Chatwoot outgoing webhook
        |
        v
n8n main -> n8n worker(s)
        |
        v
Volitex AI Inbox REST API
        |
        v
Meta
```

The first KVM 4 is shared by Client 1, Client 2, and later clients until measured production indicators justify a larger or separated deployment. One VPS per client is not the default design.

### Status labels

- [ALREADY DONE] — present in this repository or the published release.
- [MANUAL] — the founder/operator must do this in a provider dashboard, Meta, Coolify, n8n, or a terminal connected to the real VPS.
- [CODEX AUTOMATABLE] — Codex can prepare, inspect, validate, or change repository-controlled material. It cannot operate an unknown provider account without access and authorization.
- [PER CLIENT] — repeated for every client account.
- [PER META ASSET] — repeated for every WABA, phone number, Instagram account, or Facebook Page.
- [ONGOING] — repeated during operations.
- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] — cannot honestly be completed before the KVM 4 exists.

Never put a real secret in this document, Git, a workflow file, a shell command, a screenshot, or an n8n workflow node. Use a password manager and Coolify/n8n secret fields.

### Division of responsibility

Codex can automate repository changes, CI/test execution, image/digest verification, compose/configuration inspection, non-secret templates, release records, and post-deployment diagnostic commands when access is provided. You personally must buy the VPS, control provider billing, enter production secrets, operate Coolify/Hostinger/Meta/n8n dashboards, approve client data and prompts, perform destructive or externally visible recovery actions, and obtain client sign-off.

## Verified release and deployment kit

Use these four immutable references together for this release:

| Coolify variable | Published immutable image |
| --- | --- |
| `VOLITEX_IMAGE` | `ghcr.io/yoanupop/volitex-ai-inbox@sha256:82d0da5993c4572fc7a84331c1033eebfe97d14d45277350ca1f8cab6a2dfa93` |
| `N8N_IMAGE` | `ghcr.io/yoanupop/volitex-ai-n8n@sha256:8c5387a96dcfb9c1eebeb944d02ecd4a8ed9953881bbb34f400bac56a604d72a` |
| `N8N_POSTGRES_IMAGE` | `ghcr.io/yoanupop/volitex-ai-n8n-postgres@sha256:f5e4fe82aa1cafcaa2829ea56f783b1258c7544b8f0a861ac8dc7a49d098e869` |
| `N8N_VALKEY_IMAGE` | `ghcr.io/yoanupop/volitex-ai-n8n-valkey@sha256:b35c85884b1ed88de5016a785afcb4a1b29886cfebd09f6c43836a3921e849f4` |

The maintained stack runs n8n 2.44.4, PostgreSQL 17.11 and Valkey 8.1.10. These PostgreSQL/Valkey references are for n8n's dedicated services; provision Inbox's pgvector-capable database and separate queue as described below. Do not substitute upstream images, mutable tags or CI build-manifest digests for these published references.

On the founder's workstation, `C:/Users/Anup/.codex/releases/Volitex-AI-Inbox/latest.json` locates the current exported ZIP and its SHA256. Check that its release source is the commit above, verify the ZIP checksum, then run `sha256sum -c SHA256SUMS` inside the extracted kit. Keep the complete kit with the protected change record. It contains:

- `release.json`: source, completed gates, publication URL, security findings and acceptance limits.
- `release-images.env`: all four immutable references, without credentials.
- `deployment/.env.n8n.example`: all three maintained n8n image pins already filled; remaining server/secret placeholders still need configuration.
- `verification/publication/`: registry references, per-image metadata and n8n source/security verification.
- `verification/n8n-acceptance.json`: exact-source integration, upgrade and recovery evidence.

The Git source example intentionally uses image placeholders; copy the verified kit's pins or the table above into Coolify. Do not blindly deploy Git `master`: a later documentation or code commit is not this verified image source. Check `/app/.git_sha` for Inbox and the runtime source markers described in the maintained-image documentation. All four images were anonymously pullable when verified; recheck access from the actual server before deployment. Future releases require all four exact-source gates and a successful publication job before replacing these pins and exporting a new kit.

# Phase 0 — Before buying the KVM 4

Do this work before promising a go-live date, but do not buy or provision the VPS until the client has signed and paid.

## 0.1 Done now

- [ALREADY DONE] The published release source is `1ea83b0832faeafbbf867496b69f75f6a992ffb8`; the private AgentBot transport and maintained n8n stack are included.
- [ALREADY DONE] All four immutable GHCR artifacts and the verified deployment kit are recorded above.
- [ALREADY DONE] docker-compose.production.yaml requires VOLITEX_IMAGE and defines migrate, rails, sidekiq, and campaign-worker. Migration must complete before the application processes start; the campaign feature remains disabled until its separate acceptance gates pass.
- [ALREADY DONE] WhatsApp and Instagram webhook controllers validate Meta signatures, enqueue work, and acknowledge accepted deliveries. WhatsApp uses /webhooks/whatsapp/:phone_number; Instagram uses /webhooks/instagram.
- [ALREADY DONE] WhatsApp webhook work is on a high-priority Sidekiq queue. Queue order is in config/sidekiq.yml.
- [ALREADY DONE] Instagram inbound deduplication is protected by the database uniqueness boundary (inbox_id, source_id) and concurrent duplicate handling.
- [ALREADY DONE] AgentBot/n8n delivery retries cover transient HTTP failures, connection failures, and timeouts before final human handoff.
- [ALREADY DONE] WhatsApp credentials and Instagram/Facebook OAuth tokens are protected by Active Record encryption when the three encryption keys are configured. WhatsApp sensitive provider configuration is separate from queryable routing metadata.
- [ALREADY DONE] deployment/n8n-queue.compose.yaml defines separate n8n PostgreSQL, n8n Valkey, n8n main, and n8n worker services. Its environment contract is deployment/.env.n8n.example.
- [ALREADY DONE] The repository contains backup_postgres.sh, restore_postgres_backup.sh, monitor.sh, check_postgres_extensions.sh, and the staging webhook load-test harness.
- [ONGOING] Review new advisories before deployment and on every upgrade; the completed release scans above do not clear future advisories.

## 0.2 Not needed yet

- [NOT NEEDED YET] A Hostinger VPS, Coolify server, live PostgreSQL, live Redis/Valkey, n8n deployment, or client Meta asset.
- [NOT NEEDED YET] A production restore drill or production monitoring alert test.
- [NOT NEEDED YET] A production messages-per-minute or client-capacity number.

## 0.3 Required before the first client is declared live

- [MANUAL] Keep SECRET*KEY_BASE, the three ACTIVE_RECORD_ENCRYPTION*\* values, Meta/OAuth/SMTP secrets, database passwords, Redis passwords, object-storage credentials, N8N_ENCRYPTION_KEY, the backup age identity, and alert-webhook credentials only in a password manager and provider secret stores.
- [MANUAL] Confirm GitHub/GHCR ownership and that Coolify can pull the exact image. If GHCR is private, use a read-only package credential stored only in Coolify.
- [MANUAL] Own DNS for inbox.volitexai.tech and the protected Coolify administration endpoint. n8n has no public domain in the selected private profile.
- [MANUAL] Prepare the Meta Developer App, Business/Tech Provider setup, WhatsApp Embedded Signup configuration, Instagram product, privacy/terms/data-deletion URLs, and required review permissions.
- [MANUAL] Prepare off-server S3-compatible storage for media/backups and an age encryption key pair.
- [MANUAL] Prepare a private alert-webhook destination and a client onboarding record.

## 0.4 Requires future infrastructure validation

- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] Actual KVM 4 CPU, RAM, disk, IOPS, network, and complete-stack headroom.
- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] Coolify private service names and networking.
- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] PostgreSQL extensions and pg_stat_statements preload.
- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] Object storage, backup/restore, reboot, restart, failure-injection, and alert delivery.
- [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] Measured throughput and safe concurrent-client capacity.

# Phase 1 — Client signed and payment received

The trigger is client signed -> payment received. Do not connect live client Meta credentials before payment and written scope are complete.

## 1.1 Commercial and onboarding handoff

**Type:** [MANUAL] [PER CLIENT] [CLIENT-LEVEL]

1. Confirm agreement, setup fee, subscription payment method, data-processing terms, support tier, and go-live date.
2. Create the client record and private folder for agreements, prompts, logos, test evidence, billing, and recovery contacts. Raw tokens belong only in the password manager.
3. Collect Meta administrator access, business/WABA/Instagram details, team members, approved FAQs/prices/policies, escalation rules, and support contact.
4. Select WhatsApp, Instagram, or both according to the contract.

**Success:** payment, scope, Meta owner, required assets, and operator are recorded. **Recovery:** pause and request missing information; do not create partial live integrations.

## 1.2 Purchase the first infrastructure

**Type:** [MANUAL] [ONE-TIME] [INFRASTRUCTURE-LEVEL]

1. Buy the Hostinger KVM 4 in the Volitex-controlled account and record invoice, VPS ID, region, IP, plan, and renewal owner.
2. Select Ubuntu 24.04 LTS unless current Hostinger/Coolify support requires another supported Ubuntu release. The planned baseline is 4 vCPU, 16 GB RAM, 200 GB NVMe; it is not a capacity guarantee.
3. Do not attach client credentials until SSH, DNS, firewall, Coolify, persistent storage, and the release record are ready.

# Phase 2 — Initial production infrastructure

The topology is one Hostinger KVM 4 with Coolify-managed private services:

```text
Public 80/443 -> Coolify proxy -> inbox.volitexai.tech -> Rails
Volitex Rails/Sidekiq -> private Volitex PostgreSQL/Valkey
Volitex ordinary Sidekiq worker -> dedicated private bridge -> n8n main
n8n main/worker -> separate private n8n PostgreSQL/Valkey
Operator browser -> localhost SSH forward -> n8n main private IP
```

docker-compose.production.yaml intentionally does not create Volitex AI Inbox PostgreSQL or Volitex AI Inbox Redis/Valkey; create them as separate private Coolify resources. deployment/n8n-queue.compose.yaml creates the n8n database, n8n Valkey, main, and worker.

## 2.1 Secure the VPS

**Type:** [MANUAL] [ONE-TIME] [INFRASTRUCTURE-LEVEL]

1. Use the Hostinger console for initial access. Create a named operator with sudo and an SSH key.
2. Open a second SSH session as that operator before disabling root/password login.
3. Update the OS and set the operating timezone if that is the policy:

```bash
sudo apt update
sudo apt -y full-upgrade
sudo timedatectl set-timezone Asia/Kolkata
```

4. Allow only SSH, HTTP, and HTTPS. Restrict SSH to an administration IP/VPN when possible. Do not expose 3000, 5432, 6379, or 5678.
5. Enable unattended security updates and provider monitoring.
6. Install PostgreSQL client tools, aws, age, curl, jq, redis-cli, and Docker access for the monitoring account.

**Success:** non-root SSH and provider console access both work; external scan shows only intended ports. **Recovery:** keep the provider console until SSH is independently verified.

## 2.2 Install Coolify

**Type:** [MANUAL] [ONE-TIME] [INFRASTRUCTURE-LEVEL]

Install Coolify using its current official installer, protect its administrator interface with TLS/access policy, register the VPS, record Coolify version/server ID/region, and configure persistent storage plus automatic restart for all production services.

**Already handled by Volitex AI Inbox:** Compose definitions. **Manual:** Coolify installation, networking, storage, and access control.

## 2.3 DNS and TLS

**Type:** [MANUAL] [ONE-TIME] [SECURITY]

Create:

| Name                      | Type   | Value           | Use            |
| ------------------------- | ------ | --------------- | -------------- |
| inbox.volitexai.tech      | A/AAAA | KVM 4 public IP | Volitex AI Inbox proxy  |

Attach inbox to Rails port 3000 and enable Coolify TLS. Do not assign any n8n service a Coolify domain. Never create public routes for either PostgreSQL, either Redis/Valkey service, n8n main or n8n worker. The n8n main service also declares `traefik.enable=false`; inspect actual generated proxy configuration during server acceptance.

**Success:** external HTTPS works with a valid certificate and private services have no public listener. **Recovery:** correct DNS/proxy/TLS before Meta configuration; do not use HTTP as a workaround.

## 2.4 Volitex AI Inbox PostgreSQL

**Type:** [MANUAL] [ONE-TIME] [INFRASTRUCTURE-LEVEL]

1. Create a private persistent PostgreSQL service with database volitex_inbox_production and role volitex_inbox restricted to that database.
2. Use a pgvector-capable immutable image. The exact-source Inbox/n8n acceptance uses `pgvector/pgvector@sha256:ad2e18408bf447f62092a8a5259e7df10505c5a0360bd1a1853ac8b8b0763da2` (`APP_PG` in `script/production/verify_n8n_acceptance.py`). This is compatibility evidence, not the clean n8n PostgreSQL security scan. Review its current scan and record the actual selected Inbox database digest before deployment; do not reuse the n8n PostgreSQL image, which does not supply pgvector.
3. Configure shared_preload_libraries=pg_stat_statements and private readiness equivalent to:

```bash
pg_isready -U <volitex-role> -d volitex_inbox_production
```

4. Keep port 5432 private and do not reuse n8n's database or role.
5. Set VOLITEX_DATABASE_URL only in a protected operator environment and run:

```bash
deployment/production/check_postgres_extensions.sh
```

The preflight must find pgcrypto, pg_trgm, vector, and pg_stat_statements, and must find pg_stat_statements in shared_preload_libraries. A plain PostgreSQL image or missing preload is a stop condition; correct it and rerun before migration.

## 2.5 Volitex AI Inbox Redis/Valkey

**Type:** [MANUAL] [ONE-TIME] [INFRASTRUCTURE-LEVEL]

Create a separate private persistent service with a generated password and authenticated readiness:

```bash
REDISCLI_AUTH="$REDIS_PASSWORD" valkey-cli ping
```

Do not share container, password, database, or namespace with n8n. Start with noeviction unless measured operation justifies a documented alternative. Keep port 6379 private.

Enable AOF persistence (`appendonly yes`, `appendfsync everysec`) on the Inbox Valkey resource. Verify these settings and its persistent data volume before accepting traffic. Abrupt power loss can still lose the latest unflushed writes; backups, idempotency and reboot validation remain necessary.

**Already handled by Volitex AI Inbox:** REDIS_URL consumption and Sidekiq priority configuration. **Manual validation:** hostname, password, persistence, memory policy, and restart behavior.

## 2.6 Deploy Volitex AI Inbox

**Type:** [MANUAL] [ONE-TIME] [APPLICATION-LEVEL]

Create a Coolify Docker Compose application using docker-compose.production.yaml and set:

```dotenv
VOLITEX_IMAGE=ghcr.io/yoanupop/volitex-ai-inbox@sha256:82d0da5993c4572fc7a84331c1033eebfe97d14d45277350ca1f8cab6a2dfa93
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker
FRONTEND_URL=https://inbox.volitexai.tech
FORCE_SSL=true
SECRET_KEY_BASE=<password-manager-secret>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<password-manager-secret>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<password-manager-secret>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<password-manager-secret>

POSTGRES_HOST=<private-volitex-postgres-host>
POSTGRES_PORT=5432
POSTGRES_DATABASE=volitex_inbox_production
POSTGRES_USERNAME=volitex_inbox
POSTGRES_PASSWORD=<volitex-postgres-secret>
REDIS_URL=redis://:<volitex-valkey-secret>@<private-volitex-valkey-host>:6379/0
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=8
SIDEKIQ_DB_POOL=8
WEB_CONCURRENCY=0
VOLITEX_AUTOMATION_NETWORK=volitex-automation
SAFE_FETCH_ALLOW_PRIVATE_NETWORK=false
N8N_AGENT_BOT_TRANSPORTS=[]

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
SMTP_PASSWORD=<smtp-secret>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
```

Configure these Meta variable names when applicable; definitions are in config/installation_config.yml:

```dotenv
META_APP_SECRET=<current-nonexposed-secret>
FB_APP_ID=<meta-app-id>
FB_APP_SECRET=<current-nonexposed-secret>
FB_VERIFY_TOKEN=<value-if-used>
IG_VERIFY_TOKEN=<instagram-webhook-verification-value>
INSTAGRAM_APP_ID=<instagram-app-id>
INSTAGRAM_APP_SECRET=<current-nonexposed-secret>
WHATSAPP_APP_ID=<whatsapp-app-id>
WHATSAPP_APP_SECRET=<current-nonexposed-secret>
WHATSAPP_CONFIGURATION_ID=<embedded-signup-configuration-id>
WHATSAPP_API_VERSION=v24.0
```

The Inbox Compose file uses `env_file: .env`; provide a protected, untracked `.env` in the deployment directory (or verify Coolify materializes that file). Setting interpolation variables alone does not replace this file. Never commit a populated `.env`. Confirm the actual containers receive the required settings. Deploy and let the migrate service run bundle exec rails db:chatwoot_prepare. Rails and Sidekiq depend on migration success.

The application services share the Compose `volitex_storage` volume at `/app/storage`. This prevents local attachments from disappearing during container replacement when `ACTIVE_STORAGE_SERVICE=local`. Record and back up the actual Coolify volume name if using local storage. The intended S3-compatible configuration still requires its own object-store backup and restore verification; the local volume test does not validate S3 credentials or availability.

For an upgrade containing the WhatsApp credential encryption migration, retain a verified pre-migration backup and all three encryption keys, then run `bundle exec rails volitex:encrypt_whatsapp_provider_configs` from the migrated release. Verify the backfill and channel delivery before accepting the release; see [credential encryption recovery](whatsapp-credential-encryption.md). Keep the original keys with retained encrypted backups. Do not roll back across this boundary without matching data and keys.

Verify:

```bash
curl --fail --silent --show-error https://inbox.volitexai.tech/health
curl --fail --silent --show-error https://inbox.volitexai.tech/api >/dev/null
```

The first response is the unauthenticated Rails health JSON containing status woot. Inspect migrate, rails, and sidekiq logs; migration, encryption-key, database, Redis, or repeated Sidekiq connection errors are stop conditions.

## 2.7 Deploy n8n queue mode

**Type:** [MANUAL] [ONE-TIME] [APPLICATION-LEVEL]

Create a second Coolify Docker Compose application from deployment/n8n-queue.compose.yaml. Copy the complete sanitized key set from deployment/.env.n8n.example into Coolify and replace placeholders. Do not create or commit deployment/.env.n8n.

Set **all three** `N8N_IMAGE`, `N8N_POSTGRES_IMAGE` and `N8N_VALKEY_IMAGE` to the verified table/kit references. The selected release has completed its exact-source gates and publication; server acceptance is still required. Both main and worker receive the same maintained n8n image, DB, queue, `N8N_ENCRYPTION_KEY`, security, SMTP and `EXECUTIONS_MODE=queue` settings. Start one worker at `N8N_WORKER_CONCURRENCY=5`; each process has `DB_POSTGRESDB_POOL_SIZE=5`. The stock `n8nio/n8n` image is not an approved substitute.

Preserve the relative directory layout: Compose loads `./n8n/runtime-policy.env` beside it. Both custom extension files are **baked into the immutable image** at `/opt/volitex/n8n-custom`; do not add a host-source mount or install community packages. Main alone mounts `n8n_data:/home/node/.n8n`; the worker does not share this home volume. Both use `init: true`, drop all capabilities, prevent privilege escalation and limit PIDs to 256. Retain the versioned 18-node/module policy. Only trusted operators may author workflows; provider/calendar/CRM integrations use reviewed HTTP APIs in this profile.

**Volume rule:** on a new KVM, create fresh `n8n_postgres_data`, `n8n_valkey_data` and `n8n_data` volumes. For an existing deployment using the old Debian PostgreSQL image, drain and stop writers, preserve backups and keys, and logically dump/restore into a **fresh** maintained PostgreSQL cluster. Never attach the old Debian PGDATA volume directly to the Alpine image. Preserve the old database/backup for recovery. Same-major Valkey AOF migration requires stopped writers, consistent persisted data, correct ownership and a verified queue recovery before resuming. See [restore and upgrade](#62-restore); do not perform a database-family change by merely swapping image pins on an existing volume.

The verified Inbox image includes private AgentBot transport. Keep `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=false`; configure only exact per-account bot/URL/IP bindings as described in Phase 4. Do not create a global private-network exception.

**Fresh-volume permission preflight (verified locally October 21):** Docker can create the mounted `/home/node/.n8n` directory as root-owned. The maintained runtime runs as UID/GID `1000:1000` and then fails with `EACCES` when creating `config`. After Coolify creates the fresh `n8n_data` volume, identify its actual Docker volume name and initialize that directory before starting main. In the operator shell, set `N8N_IMAGE` to the verified immutable reference above and `N8N_DATA_VOLUME` to that exact volume name:

```bash
docker volume inspect "$N8N_DATA_VOLUME" >/dev/null
docker run --rm --network none --user 0:0 --entrypoint sh \
  --mount "type=volume,source=$N8N_DATA_VOLUME,target=/home/node/.n8n" \
  "$N8N_IMAGE" -c 'chown 1000:1000 /home/node/.n8n && chmod 0700 /home/node/.n8n'
docker run --rm --network none --user 1000:1000 --entrypoint sh \
  --mount "type=volume,source=$N8N_DATA_VOLUME,target=/home/node/.n8n" \
  "$N8N_IMAGE" -c 'test -w /home/node/.n8n'
```

This isolated one-shot initialization changes only the fresh volume's top-level directory. Main and worker retain their non-root security settings. For restored/existing volumes, inspect file ownership and retained encryption configuration separately; do not recursively change or replace existing data as a startup shortcut. Verify readiness after initialization before opening the editor.

Before either Compose application is deployed, select a non-conflicting RFC1918 subnet and create one dedicated internal Docker bridge. For example, only after confirming that the example subnet is unused:

```bash
docker network create --internal --subnet 172.28.8.0/24 volitex-automation
```

Set `VOLITEX_AUTOMATION_NETWORK=volitex-automation` in both applications and `N8N_PRIVATE_IP=172.28.8.10` in the n8n application, using the actual reserved subnet/IP rather than blindly copying these examples. Compose attaches only the ordinary Inbox worker and n8n main to this shared bridge. n8n worker/database/Valkey remain on the separate n8n application network; Rails and the campaign worker remain on the Inbox application network. Confirm actual Coolify network membership, including any additional automatically attached networks.

Required topology:

- No n8n service has a public domain or host-port mapping.
- n8n-main uses the reserved private IP, and its worker/database/Valkey have no membership on the shared automation bridge.
- QUEUE_BULL_PREFIX=volitex:n8n and its password are separate from Volitex AI Inbox Redis.
- N8N_EDITOR_BASE_URL is http://localhost:5678 for the operator's local SSH forward. Keep secure cookies enabled; verify actual browser login, logout, MFA and recovery through the tunnel before activation.
- N8N_WEBHOOK_URL is http://n8n-main:5678 for signed private deliveries; N8N_PROXY_HOPS=0 because this path has no HTTP proxy.
- Main and worker load the same versioned node/module policy from deployment/n8n/runtime-policy.env.
- Keep n8n_data, n8n_postgres_data, and n8n_valkey_data attached across restart/replacement.

Open the editor through an SSH forward using the actual reserved private IP:

```bash
ssh -N -L 127.0.0.1:5678:172.28.8.10:5678 <operator>@<server>
# In another local terminal:
curl --fail --silent --show-error http://localhost:5678/healthz/readiness >/dev/null
```

Set the n8n owner password and MFA, confirm SMTP recovery, verify tunnel/browser recovery, and run n8n audit. The Compose healthcheck uses /healthz/readiness internally. Add operator-controlled N8N_AGENT_BOT_TRANSPORTS bindings to the protected Inbox environment using each account/bot identity, its exact private webhook URL and the reserved main IP; see the private transport report. Credentials and IP bindings must not be selected from customer input. n8n-to-Inbox requests continue to use the fixed public Inbox HTTPS origin and scoped bot credentials.

# Phase 3 — Meta production configuration

## 3.1 One-time Meta App configuration

**Type:** [MANUAL] [ONE-TIME] [META-LEVEL]

1. In Meta Developer Dashboard confirm the App, Business/Tech Provider relationship, business verification, app mode, domains, privacy/terms/data-deletion URLs, and contact email.
2. Add inbox.volitexai.tech to app domains. If connect.volitexai.tech participates in the browser flow, add/validate it too.
3. Configure Instagram Login/Business Login. This repository requests instagram_business_basic, instagram_business_manage_messages, and instagram_business_manage_comments.
4. Add this exact OAuth redirect:

```text
https://inbox.volitexai.tech/instagram/callback
```

The callback signs/verifies state with INSTAGRAM_APP_SECRET and uses the account ID in state. 5. Configure WhatsApp Embedded Signup and create its configuration ID. The dashboard receives WHATSAPP_APP_ID, WHATSAPP_API_VERSION, and WHATSAPP_CONFIGURATION_ID. 6. Complete current Meta App Review/business-verification requirements for the actual WhatsApp and Instagram capabilities. Meta permission names can change; verify the live dashboard. 7. Configure the remediated App Secret without exposing it. 8. Configure these data-deletion/deauthorization routes if required:

```text
https://inbox.volitexai.tech/webhooks/meta/deauthorize
https://inbox.volitexai.tech/webhooks/meta/data_deletion
https://inbox.volitexai.tech/data-deletion/<confirmation_code>
```

**Already handled by Volitex AI Inbox:** OAuth callback routes, state signing, channel create/update, token encryption when configured, and webhook signature code. **Manual:** Meta approvals, app settings, domains, permissions, and external secrets.

## 3.2 WhatsApp asset connection

**Type:** [MANUAL] [PER META ASSET] [PER CLIENT]

Use WhatsApp Embedded Signup through the authenticated Inbox dashboard:

1. The client's Meta administrator completes the Meta flow.
2. Meta returns code, business_id, waba_id, and phone_number_id.
3. The authenticated Volitex AI Inbox endpoint exchanges the code, fetches phone information, creates/reauthorizes the channel, encrypts the token, and sets up webhooks.
4. The callback is:

```text
https://inbox.volitexai.tech/webhooks/whatsapp/<client-phone-number>
```

5. Confirm phone registration and WABA billing/payment.
6. If an approved manual Cloud API path is required, enter token, phone number ID, and business account ID only in the authenticated Inbox UI. Never put client tokens in n8n.

**Success:** correct account/channel, unique phone number, successful Meta subscription, signed test reaches correct inbox. **Recovery:** inspect channel health and Meta subscription, then reauthorize; do not reuse a partial mapping blindly.

## 3.3 Instagram asset connection

**Type:** [MANUAL] [PER META ASSET] [PER CLIENT]

1. Confirm Business/Creator account and required linked Meta/Facebook relationship.
2. In authenticated Inbox choose Settings -> Inboxes -> Add Instagram.
3. Complete OAuth and return to /instagram/callback.
4. The callback exchanges the code, obtains a long-lived token/details, creates or updates the channel inside the current account, and subscribes messages, message_reactions, messaging_seen, and comments.
5. Send a test DM. Use reauthorization for expiry/revocation; do not edit the database.

Instagram token encryption is enabled when Active Record encryption is configured.

## 3.4 connect.volitexai.tech boundary

connect.volitexai.tech is not present in this repository. It is an external onboarding surface, not a Rails route that Codex can verify from source.

If used:

- [MANUAL] verify its DNS/TLS, Meta redirects, session handoff, account selection, and errors;
- [MANUAL] confirm it hands off to deployed authenticated Inbox OAuth/embedded-signup endpoints and never logs client tokens;
- [MANUAL] complete one test with a non-production Meta asset;
- [CODEX AUTOMATABLE] Codex can review/change this repository's receiving endpoints, but cannot validate external Connect without its source/system access.

Do not describe Connect as repository-integrated until this end-to-end test passes.

# Phase 4 — First-client onboarding

## 4.1 Account and inbox

**Type:** [MANUAL] [PER CLIENT]

1. Keep ENABLE_ACCOUNT_SIGNUP=false.
2. In the authenticated Super Admin dashboard, open Accounts > New account and save the tenant name and locale. New accounts created through Super Admin use `ACCOUNT_LEVEL_FEATURE_DEFAULTS`; when that record is absent, this creation path uses the enabled defaults in `config/features.yml`. Other creation APIs retain their established behavior. An explicitly configured empty/disabled default list remains authoritative. Existing accounts are not backfilled or changed.
3. Create the customer user under Users (or select the existing verified user), then create an Account user membership with the new account, that user and the `administrator` role. Super Admin access does not automatically grant customer-account membership. Use the authenticated password reset/invitation flow and protected credentials, never passwords pasted in chat or shell arguments.
4. Record ACCOUNT_ID privately. Create only purchased inboxes, agents and least-privilege roles. Verify the new administrator can access only assigned accounts and an ordinary agent cannot mutate Quick Menus.
5. Store approved tier/features/niche rules in the client record or approved configuration. Defaults do not enable premium Captain features or provide Meta assets, AgentBot credentials or a working n8n workflow. Configure those separately; routine account creation does not require the legacy Rake task.

**Bulk campaign gate:** WhatsApp campaigns remain disabled in shipped defaults. The new durable recipient ledger, bounded retries, pacing, separate campaign worker and recovery tests are documented in [campaign release acceptance](campaign-release-2026-10-17.md). Deploy the campaign worker from the same application digest, verify its heartbeat/alerts and resource limits, and back up before the ledger migration. Keep the feature disabled until the approved small live campaign, delivery reconciliation, consent/opt-out procedure and KVM workload/recovery gates pass. Never reset unknown outcomes or roll back to the old sender against a used ledger. These campaign-specific gates do not invalidate the existing one-to-one automation evidence.

## 4.2 n8n machine identity and routing

**Type:** [MANUAL + CODEX AUTOMATABLE] [PER CLIENT] [SECURITY]

From the running Volitex AI Inbox release container:

```bash
bundle exec rails 'volitex:create_n8n_agent_bot[ACCOUNT_ID,http://n8n-main:5678/webhook/account-ACCOUNT_ID]'
```

Replace `ACCOUNT_ID` in both places with the actual numeric account ID. Use a unique per-account route; the bot ID is obtained after creation. Before attaching the bot or enabling AI, set the protected Inbox environment's `N8N_AGENT_BOT_TRANSPORTS` to an exact binding, for example:

```json
[{"account_id":1,"agent_bot_id":7,"url":"http://n8n-main:5678/webhook/account-1","ip_addresses":["172.28.8.10"]}]
```

Replace both IDs, the route and reserved IP with the actual values. Apply the environment to the Inbox services, restart the ordinary Sidekiq worker so it loads the binding, and verify the route resolves to exactly that reserved main IP. Keep `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=false`. The binding contains no signing secret; store secrets only in the dedicated credentials below.

Retrieve token and signing secret from the authenticated Inbox dashboard and enter them directly into dedicated n8n credentials. Do not print them in a shell or put them in a workflow node.

Configure n8n with the exact Account ID and AgentBot ID, the client webhook path, AgentBot HMAC credential, tenant-specific workflow, and approved client automation. Attach the AgentBot to the client's automation inbox and enable AI only after human takeover passes.

The contract in docs/operations/n8n-control-plane.md requires Inbox delivery ID/timestamp/signature verification, fresh automation_delivery_id values, idempotency on reuse, human ownership after takeover, and final handoff only after real Inbox-to-n8n retry exhaustion.

## 4.3 Automation and handoff

**Type:** [MANUAL] [PER CLIENT]

Load approved niche/FAQ/price/policy/knowledge material; configure escalation, office hours, booking, lead fields, notifications, honest bot identity, human escalation, and team access. Keep client-specific credentials and workflow IDs in the client record, not this repository.

# Phase 5 — Production verification and go-live gate

Record timestamp, operator, release commit, image digest, and evidence. Do not declare live until mandatory checks pass.

## 5.1 Mandatory

### Infrastructure

- [MANUAL] Inbox /health returns healthy over public TLS; n8n /healthz/readiness is healthy through the private operator tunnel, with no public n8n route.
- [MANUAL] migrate completed; Rails and Sidekiq are healthy.
- [MANUAL] PostgreSQL extension preflight passed.
- [MANUAL] Four database/Valkey services are private and persistent.
- [MANUAL] Ports 3000, 5432, 6379, 5678, and n8n-worker are not public.
- [MANUAL] Coolify image digest matches the release record.
- [MANUAL] Object-storage upload/download works.
- [MANUAL] SMTP sends a recovery/notification test.

### Meta and messages

- [MANUAL] Valid WhatsApp signature accepted; missing/invalid rejected.
- [MANUAL] WhatsApp inbound reaches only the client inbox.
- [MANUAL] Human and n8n WhatsApp outbound work.
- [MANUAL] Human takeover stops bot replies and a later bot reply is rejected.
- [MANUAL] Instagram inbound/outbound works when purchased.
- [MANUAL] Duplicate WhatsApp/Instagram delivery creates one inbound message.
- [MANUAL] Duplicate n8n automation_delivery_id creates one outgoing message.
- [MANUAL] Meta verification challenge succeeds.
- [MANUAL] WABA billing/payment and phone status are active.

### Failure and recovery

- [MANUAL] Controlled staging n8n worker stop demonstrates queued work drains after recovery.
- [MANUAL] Staged timeout/502/503/connection failure demonstrates bounded retries and final handoff only after exhaustion.
- [MANUAL] Rails, Sidekiq, n8n main, and worker restart individually.
- [MANUAL] VPS reboot recovers persistent services.
- [MANUAL] Encrypted backup and isolated Volitex AI Inbox restore succeed.
- [MANUAL] Test monitoring alert reaches the operator.

### Client acceptance

- [MANUAL] Client approves AI answers, handoff, team access, and test messages in writing.
- [MANUAL] Client receives Inbox/team training.
- [MANUAL] Client understands Meta charges are separate from Volitex AI Inbox charges.

## 5.2 Recommended

- [RECOMMENDED] Run docs/operations/webhook-load-test.md in isolated staging with multiple tenants, duplicates, bursts, slow/unavailable n8n, stopped workers, and database/Redis failure.
- [RECOMMENDED] Run n8n audit and resolve applicable high-risk findings.
- [RECOMMENDED] Run ten rapid messages per enabled channel.
- [RECOMMENDED] Confirm an external backup object can be listed/downloaded without exposing contents.

## 5.3 Scaling-only

- [SCALING-ONLY] Multi-worker n8n tuning.
- [SCALING-ONLY] Multiple Rails/Sidekiq instances.
- [SCALING-ONLY] PostgreSQL pool/slow-query tuning beyond first-client baseline.
- [SCALING-ONLY] Dedicated DB/Redis hosts or another VPS.

# Phase 6 — Backups, restore, and monitoring

## 6.1 Backups

**Type:** [MANUAL] [BEFORE GO-LIVE + ONGOING] [BACKUP]

Create a root-owned environment file outside Git:

```dotenv
VOLITEX_DATABASE_URL=postgresql://<volitex-role>:<password>@<private-host>:5432/volitex_inbox_production
N8N_DATABASE_URL=postgresql://<n8n-role>:<password>@<private-host>:5432/volitex_n8n
BACKUP_S3_URI=s3://<off-server-bucket>/volitex
AWS_ENDPOINT_URL=https://<s3-compatible-endpoint>
AGE_RECIPIENT=<age-public-recipient>
AGE_IDENTITY=/etc/volitex/backup-age-key.txt
```

Run deployment/production/backup_postgres.sh daily and before every migration/risky data change. It dumps both databases, validates with pg_restore --list, encrypts with age, uploads, downloads, decrypts, and validates again.

Record UTC object path, operator, status, and retention. Enable object-storage versioning/lifecycle/replication. The script does not replace media backup, VPS snapshots, n8n workflow exports, or secret retention.

Retain the age identity, three Active Record keys, SECRET_KEY_BASE, N8N_ENCRYPTION_KEY, exact image/database/Valkey digests, and backup identifiers together.

## 6.2 Restore

**Type:** [MANUAL] [BEFORE GO-LIVE + QUARTERLY] [BACKUP]

Use an isolated database, never production:

```bash
export RESTORE_DATABASE_URL='postgresql://<restore-admin>:<password>@<isolated-host>:5432/volitex_inbox_restore_test'
export BACKUP_S3_URI='s3://<off-server-bucket>/volitex'
export AGE_IDENTITY='/etc/volitex/backup-age-key.txt'
deployment/production/restore_postgres_backup.sh '<UTC-timestamp>/volitex.dump.age' '<latest-schema-version>'
```

The script decrypts, validates and restores with pg_restore --clean --if-exists. The schema-version argument additionally checks the Rails schema_migrations table. For n8n, use the same script against an isolated n8n database with its dump and omit that Rails-only argument. Then start the pinned n8n version against the restored database and verify workflows/credentials with the retained N8N_ENCRYPTION_KEY. A successful archive restore alone is not application acceptance. Destroy the isolated restore DB after evidence is recorded.

## 6.3 Monitoring

**Type:** [MANUAL] [ONGOING] [MONITORING]

Run deployment/production/monitor.sh every minute from the VPS or trusted monitoring host:

```dotenv
INBOX_HEALTH_URL=https://inbox.volitexai.tech/health
N8N_HEALTH_URL=http://<reserved-private-n8n-main-ip>:5678/healthz/readiness
ALERT_WEBHOOK_URL=<private-alert-webhook>
VOLITEX_DATABASE_URL=<private-url>
N8N_DATABASE_URL=<private-url>
VOLITEX_REDIS_URL=<private-url>
N8N_REDIS_URL=<private-url>
MONITOR_DISK_PATH=/
SIDEKIQ_QUEUE_NAMES="critical high medium default mailers campaigns"
```

All four database/Redis URLs above are required. The script checks health, DB connection headroom, Redis/Valkey connectivity/evictions, Sidekiq backlog, memory, unhealthy containers, disk, and n8n error/crashed executions from the last five minutes. Run it every minute and verify alert delivery independently. Reconcile external side effects before replaying a failed execution.

Its defaults are 85% memory, 85% disk, and 100 jobs per listed queue. They are early-warning defaults, not capacity guarantees. **Establish baseline during initial production/load test.**

Add provider/external monitoring for CPU, network, disk IOPS, TLS/DNS expiry, n8n execution failures/queue age, PostgreSQL storage/locks/slow queries, Redis memory/evictions, Meta delivery errors, application errors, and webhook acknowledgement latency.

## Publishing or replacing an active n8n workflow

Pause Inbox automation delivery by stopping the ordinary Sidekiq service during the controlled update; queued jobs must stay in persistent Redis. Drain running n8n executions and reconcile any interrupted external effects, then stop main and all workers before importing a replacement graph. Use a one-shot n8n CLI container on the private n8n network with the same maintained image (including its baked custom nodes), encrypted credentials key, runtime policy and database configuration to import and publish. Verify the published active-version graph contains the intended operations. Start main and workers, wait for both readiness checks, verify the authenticated workflow, then resume Inbox Sidekiq delivery. Keep human takeover available throughout.

A repeat acceptance run observed the database holding the newly published graph while an execution still used the former staging operations after import/publish beside a running main. Do not treat a successful CLI import or main-only readiness as proof that every worker is executing the intended graph. The acceptance harness now uses the stopped-writer procedure and checks the active-version graph before resuming delivery.

# Phase 7 — Ongoing operations

## Daily during first-client hyper-care

**Type:** [MANUAL] [ONGOING]

- Check Inbox/n8n health, Coolify events, and logs.
- Check Sidekiq critical/high queue age and backlog.
- Check n8n failed executions and worker queue age.
- Check Meta delivery errors, token/permission failures, subscriptions, and WABA phone health.
- Review AI responses, handoffs, duplicate reports, and client-facing errors.
- Confirm last backup and off-server object.
- Check disk and memory pressure.

## Weekly

Review CPU/RAM/disk trends, PostgreSQL connections/locks/slow queries, Redis memory/evictions, Sidekiq latency, n8n backlog, webhook latency/error rate, object-storage use, alert delivery, access membership, and DNS/TLS expiry.

## Per release or migration

1. [CODEX AUTOMATABLE] Review, test, bundle-audit, publish immutable image, and record commit/digest.
2. [MANUAL] Take/verify encrypted off-server backups of both DBs.
3. [MANUAL] Deploy new digest to staging and run smoke/failure tests.
4. [MANUAL] Change only VOLITEX_IMAGE for app-only changes.
5. [MANUAL] Run production migration and inspect the migration service.
6. [MANUAL] Verify health, webhooks, n8n, queues, backup, and alerts.

For an app-only regression, redeploy the previous known-good digest. Do not roll back across migration or credential-encryption boundaries without matching backup and keys.

The verified release also includes `20261011000000`, which repairs the n8n delivery uniqueness index in databases initialized from a schema that omitted it. Back up before upgrade. The concurrent index migration stops on duplicate deliveries or an invalid existing index without deleting data; inspect and resolve intentionally before retrying. Its down migration is deliberately irreversible so rollback cannot remove idempotency protection. Preserve the compatible schema during an app-only rollback, or use a separately approved restore/forward-fix plan. Quick Menu rollback itself deletes saved menus.

The release requires all three Active Record encryption variables during production startup and runs `bundle check` without installing dependencies. A missing key or missing gem is a deployment failure to correct in configuration/build; do not bypass these checks. The actual asset-precompile task has a narrowly scoped key exemption and is not a runtime readiness check.

# Phase 8 — Additional clients on shared infrastructure

## A. Done once globally

Hostinger, Coolify, firewall, DNS, TLS, Volitex AI Inbox PostgreSQL/Valkey, n8n queue mode/PostgreSQL/Valkey, backup, monitoring, Meta App configuration, operator access, and release records.

## B. Done per client

Commercial/payment record, Volitex AI Inbox account, admins/agents, inboxes, team permissions, dedicated n8n AgentBot/HMAC secret, routing, prompts/knowledge, handoff rules, alerts, UAT, and sign-off.

## C. Done per WABA/Instagram/Page

Asset connection, token/permission validation, billing/phone status, webhook subscription, reauthorization path, and inbound/outbound testing.

## D. Done whenever infrastructure changes

Backup, immutable image verification, migration validation, staging smoke/failure tests, deployment, rollback record, and post-change monitoring.

## E. Done continuously

Health, queues, n8n failures, DB/Redis pressure, backups, Meta delivery, and client-facing errors.

### Tenant isolation

The application associates accounts, inboxes, channels, conversations, AgentBots, and API access with account/inbox boundaries. WhatsApp routing uses phone number; Instagram routing uses subscribed account/channel. Instagram duplicate keys include inbox_id. n8n identities are dedicated per account. Outgoing replies require the account/conversation path and assigned AgentBot. Separate Redis/Valkey boundaries prevent n8n Bull jobs from sharing Sidekiq/ActionCable storage.

This is logical, not physical, isolation. Before each go-live verify account/inbox, Meta asset IDs, n8n account/bot IDs, and test messages. If any asset maps incorrectly, stop and disable automation.

# Phase 9 — Scaling decision

Do not promise a fixed client count or messages-per-minute limit. Measure the KVM 4 with the staging harness and real production baseline.

Watch CPU saturation, RAM/OOM, PostgreSQL CPU/storage/locks/slow queries/connections, Redis memory/evictions/latency, Sidekiq latency/backlog, n8n execution backlog/worker resources/failures, webhook p50/p95/p99/errors, processing latency/duplicates, disk/IOPS, network, and Meta throttling/delivery errors.

**Establish baseline during initial production/load test.** Scale when the same customer-facing signal remains degraded after ordinary queue/workflow tuning.

```text
KVM 4
  -> larger VPS when host is bottleneck
  -> more Sidekiq/n8n workers when worker backlog is bottleneck
  -> DB or Redis separation when shared-state pressure is bottleneck
  -> multiple Rails/Sidekiq instances when app concurrency is bottleneck
  -> additional VPS/regions when capacity or failure domain requires it
```

Do not split one client per VPS unless a concrete security, compliance, contractual, or measured scaling requirement makes shared tenancy inappropriate.

# Phase 10 — Recovery and disaster scenarios

The single-KVM architecture can take every tenant down during a VPS/Hostinger outage. Persistent volumes improve restart recovery but do not provide HA. Off-server backups limit data loss but do not create zero-downtime failover.

| Scenario                 | Automatic behavior                                      | Operator action                                                              | Verification                     |
| ------------------------ | ------------------------------------------------------- | ---------------------------------------------------------------------------- | -------------------------------- |
| Volitex AI Inbox Rails crash      | Coolify/Docker restarts; health fails while unavailable | Inspect logs/health/DB/Redis; restore old image only for app-only regression | Health, login, inbound/outbound  |
| Sidekiq crash            | Restart; accepted Redis jobs remain queued              | Restart, inspect queue/retry/dead sets                                       | One webhook -> one message       |
| n8n main crash           | Private webhook/editor unavailable until recovery      | Restart and inspect queue/logs                                               | Health and one workflow          |
| n8n worker crash         | Restart; Bull jobs remain stored                        | Restart and inspect failed executions                                        | One workflow completes once      |
| Redis/Valkey crash       | Restart may recover persisted state                     | Recover, ping, inspect backlog/retries                                       | Queue drain and duplicate check  |
| Volitex AI Inbox PostgreSQL crash | Restart/recovery if volume intact                       | Verify extensions; use approved restore plan if needed                       | Health, records, channel test    |
| n8n PostgreSQL crash     | n8n unavailable or workflows fail                       | Recover and verify encryption key                                            | Owner login, workflow, execution |
| VPS reboot               | Coolify/services should restart                         | Controlled reboot; inspect every service                                     | Full reboot checklist            |
| Disk pressure            | Alerts; writes/backups may fail at exhaustion           | Preserve evidence, clean approved data, expand disk                          | Disk, backup, message            |
| VPS/Hostinger outage     | No cross-host failover                                  | Provider recovery or replacement host, restore, DNS, smoke                   | Full go-live checklist           |
| Bad deployment           | Selected digest runs; migration may block dependents    | Redeploy old digest for app-only issue; forward-fix data changes             | Smoke, queues, Meta, n8n         |
| Migration failure        | Rails/Sidekiq remain blocked behind migrate             | Stop, preserve backup, fix forward or approved restore                       | Migration/readiness/smoke        |
| Corrupt DB               | No automatic logical repair                             | Preserve original, isolated restore, approved recovery                       | Counts, health, acceptance       |
| Lost encryption keys     | Encrypted values cannot decrypt                         | Retrieve exact keys; otherwise reauthorize assets                            | Reauth and message               |
| Expired Meta token       | Provider calls/webhooks fail                            | Reauthorize and verify permissions/status                                    | Inbound/outbound                 |
| Meta webhook failure     | Meta retries according to Meta behavior                 | Check signature, token, subscription, TLS, health, Sidekiq, Meta logs        | Signed webhook/duplicate         |

Recovery time and recovery-point objectives are not promises until restore and VPS-replacement drills are measured. Record measured durations.

# Phase 11 — Final chronological checklist

1. [MANUAL] [ONGOING] Organize credentials, Meta access, domains, client materials, pricing, and operators.
2. [ALREADY DONE] Record verified release source `1ea83b0832faeafbbf867496b69f75f6a992ffb8` and its four successful gates.
3. [ALREADY DONE] Record all four immutable images and verify the deployment kit checksums from the release section above.
4. [MANUAL] Finalize packages, features, pricing, contract, and demo.
5. [MANUAL] Begin sales/outreach.
6. [MANUAL] [PER CLIENT] Client signs.
7. [MANUAL] [PER CLIENT] Payment and onboarding scope are recorded.
8. [MANUAL] Purchase and secure KVM 4.
9. [MANUAL] Configure OS, SSH, firewall, DNS, and Coolify.
10. [MANUAL] Provision Volitex AI Inbox PostgreSQL/Valkey, persistence, extensions, and healthchecks.
11. [MANUAL] Run PostgreSQL preflight.
12. [MANUAL] Configure encrypted off-server backups and monitoring.
13. [MANUAL] Deploy Volitex AI Inbox with immutable VOLITEX_IMAGE.
14. [MANUAL] Confirm migration, Rails, Sidekiq, object storage, SMTP, and logs.
15. [MANUAL] Deploy n8n queue mode with immutable dependency images.
16. [MANUAL] Confirm n8n health, MFA, SMTP recovery, audit, and volumes.
17. [MANUAL] [PER META ASSET] Configure Meta domains, redirects, permissions, webhooks, and production credentials.
18. [MANUAL] [PER CLIENT] Create account, teams, inboxes, and permissions.
19. [MANUAL] [PER META ASSET] Connect WhatsApp and/or Instagram.
20. [MANUAL] [PER CLIENT] Create AgentBot and tenant workflow.
21. [MANUAL] [PER CLIENT] Configure prompts, automation, handoff, notifications, and approved behavior.
22. [MANUAL] Run smoke, duplicate, signature, retry, restart, reboot, restore, and alert tests.
23. [MANUAL] [PER CLIENT] Obtain client UAT sign-off and declare live.
24. [ONGOING] Perform hyper-care, backups, operations review, and release controls.
25. [PER CLIENT] [PER META ASSET] Repeat client/asset onboarding for later clients.
26. [REQUIRES FUTURE INFRASTRUCTURE VALIDATION] Scale only when measured signals justify it.

# Final distinction

“Volitex AI Inbox is technically production-ready” means the frozen repository, security fixes, webhook handling, tenant controls, deployment definitions, backup/restore tooling, monitoring tooling, and immutable image are prepared for deployment. That is the verified release status above, within its documented private n8n capability and security scope.

“Volitex AI Inbox is actually deployed and operating in production for a paying client” means the KVM 4 exists and the real deployment has passed infrastructure, Meta, backup, monitoring, smoke, failure, reboot, and client-acceptance checks. That state does not exist until the manual first-client sequence is completed.

Preparation is a release-specific gate supported by the exact-source evidence above. Later commits require their own gates; this runbook does not approve arbitrary source changes. The first real deployment requires the release verification record, careful operator execution, and measured validation of the single-VPS failure domain.


## Operational configuration requirements

Use `docker/Dockerfile` and `docker-compose.production.yaml`, not development Compose or an upstream image. The verified publication is recorded above; future publication remains gated. All application processes and migration use the same required `VOLITEX_IMAGE`; set it to the authorized Volitex AI Inbox GHCR digest, never a tag. The required interpolation has no fallback, but Compose does not validate registry ownership: the operator must verify the published digest and `/app/.git_sha`. A prior CI build-manifest digest is not a pullable release.

### Initial shared-host concurrency and database budget

Do not increase Puma to 2-4 processes solely because multiple tenants share the service. Begin with one Puma process (`WEB_CONCURRENCY=0`), `RAILS_MAX_THREADS=5`, and ordinary `SIDEKIQ_CONCURRENCY=8`, `SIDEKIQ_DB_POOL=8` from the protected deployment environment. Campaigns remain a separate two-thread, one-CPU/1536-MiB worker; Compose explicitly sets its concurrency and DB pool to 2. No concurrency was increased by this reconciliation.

Application pool upper bounds for one replica of each service are 5 web + 8 ordinary + 2 campaign = 15 connections. Temporarily allow up to 5 for migration and 5 for an operator console: 25. This is a configured pool budget, not measured throughput or guaranteed simultaneous demand. n8n's main and worker each use `DB_POSTGRESDB_POOL_SIZE=5`: budget 10 application connections on their dedicated PostgreSQL server, plus its backup/monitor/admin reserve. Do not combine it with the Inbox database. Reserve additional connections for Coolify, backups, monitoring, administrative access and PostgreSQL reserved slots. Record actual `SHOW max_connections` and `pg_stat_activity` before launch. Do not raise max_connections blindly.

Every additional replica or Puma child multiplies its own pool; clustered Puma may also retain a parent/preload connection pool. Recalculate conservatively before changing WEB_CONCURRENCY. Measure RSS, CPU, queue age, DB checkout waits, webhook latency and ordinary-agent responsiveness under the intended initial workload before tuning. A 4-vCPU/16-GB host is a bounded shared starting point, not unlimited capacity.

### Worker health, logs, queue durability and alerts

The ordinary and campaign Compose health checks require a recent Sidekiq registration for the current container host and its expected queue (`critical` versus `campaigns`). The legacy script filename `campaign_worker_health.rb` is retained for compatibility; `SIDEKIQ_HEALTH_QUEUE` selects the ordinary worker. Docker health status alone does not restart a live but unhealthy process. Configure Coolify alerts for unhealthy, stopped and restarting expected services, and prove operator delivery by stopping a disposable worker during acceptance. Configure an external uptime check: a monitor on the failed VPS cannot report a total host/network loss.

All application and n8n Compose services now use Docker's `local` log driver with 10-MB files and five files per container. This bounds local logs, not remote retention; verify the actual deployed driver/options with Docker inspect. Set Rails stdout logging, retain redaction, do not enable verbose request-body/token logging. Preserve a bounded off-host incident window through the existing operator tooling; no paid logging service is required by this change.

Both queue stores require persistent volumes, `appendonly yes`, `appendfsync everysec`, and `maxmemory-policy noeviction`. n8n Compose specifies them explicitly; configure the separate Inbox Valkey resource the same way. Check `CONFIG GET` and `INFO persistence` on the actual servers without recording passwords. The monitor now rejects empty/unauthorized INFO output, disabled AOF, failed AOF writes or RDB saves, eviction, and failed Docker health inspection. It queries `INFO memory stats persistence` as separate sections. Configure the monitor's database/Redis URLs and `SIDEKIQ_QUEUE_NAMES=critical high medium default mailers campaigns` in a root-owned protected environment file. Run it every minute and verify both a healthy run and a delivered failure alert; a failed alert transport must be detected by an independent scheduler/uptime check. Do not assume the script installs its own cron or alert destination.

Check Redis/Valkey startup for persistence errors and the vendor memory-overcommit warning. Apply the intended Linux `vm.overcommit_memory=1` setting through the reviewed server provisioning procedure, with memory limits/alerts; no host sysctl was changed during local verification. Every-second AOF can lose the latest unflushed writes after abrupt power loss. Off-server backup RPO can be much larger; document the actual schedule and measured restore time.

### Backups include more than database dumps

The existing encrypted PostgreSQL backup scripts cover both databases and download/decrypt/list verification. `pg_restore --list` is archive validation, not an actual restored application. Before client traffic, restore to isolated databases, start the matching release, decrypt test credentials, open restored attachments, execute a synthetic n8n workflow and record actual recovery time and backup age.

Local attachment storage is supported by the shared persistent `/app/storage` volume; S3 is optional, not mandatory or newly purchased infrastructure. If local storage is selected, set `ACTIVE_STORAGE_SERVICE=local` and omit unused object-store credentials. Record the actual Coolify volume names for Inbox attachments, n8n data and both Valkey stores. Establish a consistent backup window by quiescing web/worker/n8n writers and gracefully flushing/stopping queue stores under an approved maintenance procedure before archiving their volumes. Encrypt archives before off-server transfer; checksum/download/restore them with the matching DB backup. For an existing object store, verify object versioning/backup and restoration instead. Preserve all three Active Record encryption keys, SECRET_KEY_BASE, N8N_ENCRYPTION_KEY and backup decryption identity in the protected off-server recovery store, never in Git, logs or the same sole VPS. A DB dump without its media and exact keys is incomplete.

### Optional error tracking and branding acceptance

If using the existing Sentry integration, configure a protected SENTRY_DSN and `DISABLE_SENTRY_PII=true`. Leave ENABLE_SENTRY_TRANSACTIONS unset unless intentionally enabling sampling; this initializer tests variable presence. Confirm a controlled operator test event is received without secrets/customer data. Sentry is optional tooling, not a claim of configured alert delivery or a requirement to purchase a service. Without it, name the operator's application/Sidekiq error-log alert mechanism and test delivery explicitly.

The current installation defaults already specify Volitex AI Inbox and `/brand-assets/` logos; dashboard/layout titles, English login/account strings, email templates and public favicon assets are branded. Existing DB overrides or cached installation settings can differ: inspect the running installation, then visually accept login, dashboard, Super Admin, a delivered test email, favicon and mobile/dark mode where supported. Internal Ruby constants, package namespaces, i18n keys, upstream attribution and API identifiers are not branding defects and must not be renamed indiscriminately.

Normal client traffic requires an authorized pullable image containing the private transport, actual KVM Inbox TLS/private-network/tunnel acceptance, migration and complete restore/reboot/alert tests, tenant/human-handoff checks and authorized channel-specific smoke tests. Verify no public n8n route or bypass port, the reserved-IP binding, only the two intended automation-bridge members, and the same enforced node/module policy on main and worker. Campaigns additionally require the small opted-in approved-template live campaign, actual delivered/read/failed reconciliation, opt-out procedure, unknown-outcome review and measured KVM resource/queue recovery acceptance. Keep the campaign feature disabled until those separate gates pass. No production action or live traffic is authorized by this runbook.

Rollback note: pair the previous application image with its matching Compose configuration. In particular, the older campaign-only health executable does not understand the new ordinary-worker queue selector; do not retain that new health command against an older image. Preserve the repaired host monitor, encryption keys and compatible recipient ledger; never downgrade to the pre-ledger sender or reset unknown outcomes. The legacy EE Docker Hub publisher is restricted to the official upstream repository. Volitex AI Inbox releases use only the explicit GHCR publication workflow; never merge or tag merely to publish.
