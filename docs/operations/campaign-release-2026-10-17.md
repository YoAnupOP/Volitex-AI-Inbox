# WhatsApp campaign delivery candidate — 2026-10-17

## Decision and scope

Campaign reliability implementation is complete enough for candidate verification, **not enabled for client traffic**. `whatsapp_campaign` remains disabled in shipped feature defaults. Normal one-to-one messaging and the previously verified Inbox/n8n round trip are separate release scopes. No live campaign, production deployment, callback change or image publication was performed.

Implementation source: `17dbb0898dad02ced7c3db6060c961617dd6354d` (initial lifecycle `8aa2c57875`, consent security `d8d8998ade`, strong-parameter compatibility `17dbb0898d`). This supersedes the old sender assessment in `first-client-readiness-2026-10-17.md`; it does not erase historical test evidence.

## Sending and recovery contract

- Inbox owns the recipient ledger, provider calls and status reconciliation. n8n is not a delivery engine.
- Account-scoped label audiences are snapshotted in batches of 500, with unique campaign/contact and nonblank destination constraints. Snapshot, campaign transition and dispatch intent are durable PostgreSQL state.
- Only WhatsApp Cloud, enabled accounts and cached approved **MARKETING** templates are accepted. Existing template personalization and provider payload construction are reused; templates are checked again before each send. Meta remains authoritative about current template availability, recipient eligibility and account limits.
- Every recipient needs an explicit inbox-specific consent record. Blocked contacts, revoked/malformed/future/wrong-inbox consent and changed/deleted phone destinations are suppressed. Inbound conversation activity does not constitute marketing consent. Public contact creation/identification strip this reserved key while preserving other custom attributes; only the authenticated account API records it. Changing an existing contact phone clears old consent.
- A send claim and attempt count commit before HTTP. Accepted/sent/delivered/read/failed/pending/retryable/sending/unknown/suppressed/cancelled are durable recipient states. Campaign completion means dispatch finished, not customer delivery.
- One shared PostgreSQL pacing slot per inbox permits at most one request per second across campaigns. Explicit throttling backs off all campaigns on that inbox. Automatic retries have a maximum of three attempts and exponential minimum delays of 30/60/120 seconds, respecting numeric or HTTP-date Retry-After.
- Only explicit provider throttling and known connection-establishment failures are retried. Read timeouts, resets, server errors and missing acceptance identifiers become **unknown**. An abandoned send claim older than two minutes becomes unknown, never an automatic resend. There is no exactly-once provider guarantee.
- A dispatch token permits only one continuing job chain. A minute recovery job repairs lost/stale chains after two minutes. Duplicate and overlapping jobs still contend on campaign and inbox locks. Legacy processing campaigns without snapshots are not automatically restarted.
- Separate `campaigns` Sidekiq queue: concurrency 2, one CPU and 1536 MiB Docker limits. Ordinary workers do not consume this queue. A fresh campaign-worker heartbeat is required for container health. This limits CPU/memory contention but does not prove shared database/Redis capacity at every workload.
- Admin-only pause/resume/cancel, cursor-paginated recipient outcomes, state counts, progress refresh and error/in-flight warnings are exposed in the existing campaign UI. Pause/cancel cannot recall an already claimed HTTP send. History cannot be deleted after snapshot. Snapshotted delivery definitions cannot be edited.
- Provider callbacks reconcile every status in the batch by provider ID or a strictly parsed opaque recipient ID constrained to the receiving inbox/account. Duplicate/out-of-order callbacks cannot downgrade delivered/read outcomes. A failed event after sent is recorded. Early callbacks cannot be overwritten by a later HTTP acceptance.
- Contact deletion redacts stored destination and consent evidence; the nullable FK preserves delivery outcomes. Account deletion cascades its campaigns/ledger normally.

## Operator configuration

Use the existing authenticated, account-scoped contact update API only when actual consent evidence exists:

```http
PATCH /api/v1/accounts/:account_id/contacts/:contact_id
Content-Type: application/json

{"custom_attributes":{"whatsapp_marketing_consent":{"status":"granted","inbox_id":123,"source":"<real consent evidence reference>","recorded_at":"<ISO8601 timestamp>"}}}
```

A contact currently holds one such inbox consent record. Record revocation with `status: revoked` or block the contact before future dispatch. This release does not invent consent, parse every natural-language opt-out, or provide a consent-import UI. Operators must record opt-outs from customer channels promptly; enforce this process before enabling marketing.

Existing campaign creation/list/update endpoints remain unchanged. New endpoints use the campaign **display ID**, with administrator authorization:

- `POST /api/v1/accounts/:account_id/campaigns/:id/pause`
- `POST /api/v1/accounts/:account_id/campaigns/:id/resume`
- `POST /api/v1/accounts/:account_id/campaigns/:id/cancel`
- `GET /api/v1/accounts/:account_id/campaigns/:id/recipients?after_id=<cursor>` (up to 100 safe outcome records)

Campaign responses include `recipient_counts` and `delivery_error`. Never retry an unknown outcome by resetting database state. Reconcile provider evidence first; a new, explicitly reviewed audience can target confirmed unsent recipients. There is no blind retry-all endpoint.

The existing scheduler cadence and three-day overdue cutoff remain intact. Review stale unsent schedules, then explicitly pause/resume if they should run. Do not reset a legacy processing campaign or roll back to the previous sender against this ledger.

## Migration and deployment

Migration `20261017000000` adds nullable campaign dispatch fields, `campaign_recipients` and `campaign_dispatch_slots`, FKs, unique indexes, state and attempt checks. No existing recipient history is fabricated and no existing campaign is sent by the migration.

Before upgrade, disable campaign sending and drain old sender jobs. Back up PostgreSQL, attachments and encryption keys. Run the established migration container command:

```bash
RAILS_ENV=production bundle exec rails db:chatwoot_prepare
```

Deploy the same digest for web, ordinary worker and campaign worker using `docker-compose.production.yaml`. Run `campaign_worker_health.rb` health checks and test alert delivery. Migration down drops the ledger: **not a safe rollback after use**. Prefer a compatible forward fix with the feature disabled; disaster rollback requires a matching verified pre-upgrade database backup and image, preserving provider reconciliation evidence.

## Executed local verification

Disposable WSL PostgreSQL databases and distinct Redis logical databases were used; no staging/customer database was reset.

- `bundle exec rspec` focused campaign services, status callbacks, worker health, campaign controls, campaign/contact models, existing campaign API/job and Cloud provider: **143 examples, 0 failures** after final status fix. Exact file list is in `.github/workflows/verify_campaigns.yml`; the local run also included `trigger_oneoff_campaign_job_spec.rb`.
- `bundle exec ruby script/production/specs/campaign_worker_recovery.rb`: actual Sidekiq process kill/restart, real PostgreSQL/Redis, loopback fake Meta, stale and overlapping jobs: **PASS**. Six intended recipients, six provider calls, five accepted, one honest unknown, zero duplicate calls, zero lost pending recipients; five stale and five overlapping jobs. Separate critical job latency 0.051 seconds during the delayed campaign request. Fresh worker heartbeat checked; child processes stopped gracefully.
- `bundle exec rspec script/production/specs/campaign_capacity_spec.rb`: **4 examples, 0 failures, 16m10s**. Real ledger/template processing and mocked HTTP provider, direct dispatcher with accelerated test clock. This is not a real-time Sidekiq/Meta throughput test. Final harness also records dispatch latency percentiles in candidate CI.
- Final consent patch regression run: **233 examples, 0 failures**, covering public/widget/account contact endpoints, contact model/action/builder, campaign dispatch, Quick Menus and both inbound services. This includes strong-parameter contact creation, public consent forgery rejection and phone-change revocation.
- Additional Quick Menu model/policy/CRUD/sending and both WhatsApp inbound service suites: **72 examples, 0 failures**. Normal interactive selection and existing inbound behavior remain covered.
- Frontend Vitest: **29 tests passed across five files** (delivery controls 7, existing store 21, campaign API 1).
- Changed frontend ESLint: zero errors, five dynamic-i18n-key warnings. Prettier checked new component/spec/workflow successfully. Existing frontend files touched by this task are normalized to LF because the repository formatter rejects CRLF.
- `pnpm exec vite build` passed during implementation (1m47s); exact final candidate CI supplies the final asset-build result.
- `node --test script/production/specs/n8n_reply.test.cjs`: **8 passed**. Existing live integration evidence is reused; no additional live messages sent.
- Disposable schema load and migration down/up passed. Required PostgreSQL extensions were created by the disposable database administrator, not by elevating the application role.
- RuboCop checked 21 changed Ruby files: residual existing CRLF diagnostics plus Contact class length above 175 after the necessary privacy callback. Correctable alignment/callback ordering offenses were fixed. These lint results are not described as green. Large legacy routes/inbound files and standalone failure/load harnesses are not included in that 21-file lint claim.
- `git diff --check` passed. Windows hook could not supply its normal SCSS tooling; commit used HUSKY=0 after explicit focused checks, not an assertion that repository-wide lint passed.

### Synthetic capacity observations

| Recipients | Snapshot s | Dispatch wall s | Direct dispatcher recipients/s | Process peak RSS MiB | Account-read probe p95 ms | Duplicate calls |
|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 1.21 | 38.11 | 26.24 | 368.0 | 1.83 | 0 |
| 2,000 | 3.90 | 86.56 | 23.11 | 370.7 | 1.48 | 0 |
| 5,000 | 3.54 | 248.60 | 20.11 | 377.5 | 1.48 | 0 |
| 10,000 | 3.47 | 589.02 | 16.98 | 399.8 | 1.41 | 0 |

Each run accepted every intended recipient once; assertions enforce accepted count and no duplicate provider calls. Database size observations ranged 38.7–56.3 MB, including test schema/fixtures. Enqueue intent took 0.005–0.011 seconds. CPU seconds: 29.44 / 61.93 / 158.76 / 311.13. Process RSS is a process lifetime high-water mark. Account reads are a database probe, **not HTTP inbound response latency**. Queue wait percentiles, peak connection count, Redis memory and full VPS load were not measured in this direct-dispatch run. Production pacing remains at most 1 request/sec/inbox (10k requires at least ~2h47 plus scheduler/network overhead), not the accelerated rates above.

Setup failures were diagnosed rather than hidden: WebMock's generic timeout initially simulated an open timeout instead of the intended read timeout; the test now explicitly covers each. Persisted fake channel fixture collisions were removed by using a fresh dedicated test DB. Concurrent load/unit fixtures on one DB caused unique-index waits; isolated unit/load DBs fixed that setup. A fractional test clock initially skipped a pacing slot; freezing the test clock fixed the harness. None is asserted a pre-existing application failure.

## Remaining campaign launch acceptance

1. Exact candidate build/boot/scan and campaign CI must pass; record their immutable identities below.
2. On KVM, verify private PG/Valkey, all three Inbox processes, durable volumes, campaign heartbeat alert, Traefik n8n identity middleware on **every** generated n8n router, no alternate ingress, backup restore and reboot recovery.
3. Approve a small opted-in test audience and a real approved marketing template; then explicitly authorize the live campaign. Verify actual delivery/read/failure callbacks, pause/resume/cancel and one rejected recipient without resending successes. Local API acceptance is not delivery evidence.
4. Run the existing bounded harness against a disposable KVM-sized environment while probing actual inbound HTTP and queue latency. Verify normal operations stay within the agreed first-client service budget; local accelerated dispatch does not establish that budget.
5. Enable `whatsapp_campaign` only for the accepted account after these gates, consent/opt-out procedures and operator review of unknown outcomes are in place.

## Candidate CI and artifact results

Initial lifecycle source `8aa2c57875`: candidate CI [39021169130](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39021169130) passed build, boot, migrations, storage/dump-restore, restart/graceful stop and Trivy 0.75.0 scan (**0 critical, 0 high, 2 medium, 1 low**). Build manifest `sha256:71c7785538784c81f87812cfe5f331249212383c839c867085ffe3e03a8616cd`. This is predecessor evidence, not the final consent-patched artifact.

Its full CE workflow [39021169144](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39021169144) remains red: **6,073 backend examples / 34 failures**; all failed full descriptions match the 16 predecessor artifacts at `fa6fa33b35` (6,042 examples / 34 failures). Frontend has the same 19 normalized failure headings as that predecessor, with no new/missing headings. Dependency manifests and lockfiles are unchanged. Broad lint/security failures are not called passing. Superseded intermediate consent-only CI runs were cancelled after the final compatibility fix; cancellation is not a pass.


### Final consent-patched source

Candidate CI [39021865040](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39021865040) **PASS** on `17dbb0898dad02ced7c3db6060c961617dd6354d`:

- OCI build manifest: `sha256:ca12f21a453e12c187a2ebaa4a376ac6c7584203892ff53e702371d72d994503`.
- Loaded/scanned image configuration: `sha256:81be96a3e8b35a300cda2ff7e6f140c83a18228c6b3e22e445fefd799b9d444d`.
- Actual final-image entrypoint/build/assets, fresh migrations, web/ordinary worker/campaign worker startup, PostgreSQL/Redis, shared storage marker, disposable PostgreSQL dump/restore, restart and graceful stop: **PASS**. Production Compose renders with required test values. These are disposable CI checks, not actual KVM acceptance.
- Trivy **0.75.0**, pinned scanner `sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa`: **0 critical / 0 high / 2 medium / 1 low**. Unfiltered JSON artifact `candidate-image-vulnerabilities` inspected. Remaining findings: Devise 4.9.4 CVE-2026-32700 / CVE-2026-40295 (existing backport/disabled-Timeoutable dispositions), dormant default JSON 2.9.1 CVE-2026-54696 (application selects patched JSON). No dependency manifests changed. CI downloaded the scanner database; its artifact digest was not retained, so this is not asserted the frozen n8n comparison database.
- Authenticated n8n reply contract: **8 tests passed**.
- Final full backend CI: **6,076 examples, 6,040 passed / 34 failed / 2 pending**. All 34 failed full descriptions match `fa6fa33b35` predecessor artifacts, with no new or absent identities. Final frontend: **3,837 passed / 19 failed**, all 19 normalized failure headings identical to the predecessor (portal/theme/appearance tests). No new/missing failed headings.

**Artifact availability:** the workflow uses `push: false` and loads the image on an ephemeral runner. The digest proves the scanned/tested build; it is **not a pullable published release**. No image was published. Before deployment, authorize retention/publication of an immutable candidate, then verify that exact available artifact's digest/boot/scan. Do not substitute this digest into a registry reference that does not exist.

**n8n ingress:** the final source's isolated Traefik ingress regression passed. The official n8n image and existing documented risk dispositions were not changed. `deployment/n8n/traefik-compression-guard.yaml` forces request `Accept-Encoding: identity`; `deployment/n8n-queue.compose.yaml` attaches `volitex-n8n-identity@file` to main, with no host port mappings or public worker/PG/Valkey router. Actual Coolify-generated HTTPS routers, middleware installation and no-bypass ingress still require the first KVM deployment procedure in the authoritative runbook. Keep n8n authoring restricted to trusted operators.

Dependency CI on final source: Bundler audit reports no vulnerable Ruby advisories. pnpm audit --prod --audit-level high remains red: **16 findings (1 high, 10 moderate, 5 low)**. The high finding is braces 3.0.3 / GHSA-vfj7-8cjw-p6xm through Tailwind/chokidar/micromatch build-tool paths; manifests are unchanged. No direct application import of these packages was found (the Enterprise source tree is absent from this checkout), and final-image checks verify Node dependency trees are absent. This is retained build-tool exposure, not a claim that the complete repository security job is green. Existing n8n findings retain their prior advisory-level dispositions and required ingress/operator restrictions.


### Final campaign lifecycle CI

[Run 39021865035](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39021865035) **PASS** on the same final source:

- Fresh schema and migration down/up: passed.
- Focused campaign/contact/API/provider/health regressions: **169 examples, 0 failures**.
- Real Redis/PostgreSQL Sidekiq crash/recovery: six intended recipients / six provider calls / five accepted / one unknown / zero duplicates / zero lost pending; five stale and five overlapping jobs. Separate critical queue probe: 0.051 seconds.
- Synthetic 1k/2k/5k/10k: **4 examples, 0 failures**. Each snapshot enqueued exactly one campaign dispatch chain, not one job per recipient. Other test-adapter jobs are unrelated fixture callbacks.
- Isolated official n8n + Traefik compression ingress regression: passed. No live WhatsApp send was performed.

Final CI measurements (mocked provider, accelerated dispatch clock; **not Meta or KVM capacity**):

| Recipients | Snapshot s | Dispatch wall s | CPU s | Process peak RSS MiB | Dispatch p50/p95/p99 ms | Account-read p95 ms | Duplicates |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 0.73 | 25.61 | 18.57 | 352.6 | 24.4 / 27.8 / 36.3 | 1.12 | 0 |
| 2,000 | 0.45 | 52.49 | 36.16 | 353.6 | 25.8 / 29.9 / 32.6 | 0.56 | 0 |
| 5,000 | 1.13 | 164.12 | 93.72 | 361.8 | 31.2 / 41.7 / 47.4 | 0.91 | 0 |
| 10,000 | 2.19 | 475.94 | 202.68 | 402.3 | 47.5 / 69.0 / 77.5 | 0.85 | 0 |

Enqueue intent: 0.0038–0.0070 seconds; database size observation: 24.5–55.3 MB. These dispatch percentiles measure direct service wall time, **not queue wait or customer delivery latency**. Production pacing, operator restrictions and the remaining campaign launch gates above remain unchanged.

**Final disposition:** implementation and focused candidate gates passed; broad CI remains red on identified baseline tests/lint and the existing build-tool audit finding. Campaigns stay disabled until approved small live-template delivery/reconciliation and actual KVM resource/ingress/recovery acceptance. Normal automation retains its previous live verification. No production/client traffic has been authorized by this report.
