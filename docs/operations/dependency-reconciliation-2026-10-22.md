# Volitex AI Inbox dependency reconciliation — October 22, 2026

## Evidence and scope

GitHub's API snapshot contains **221 open alerts: 11 Critical, 104 High, 91 Medium, 15 Low**. The [complete inventory](dependency-reconciliation-2026-10-22.csv) records every alert number, package, manifest, advisory, reported range, patched version, installed n8n versions and disposition. No GitHub alert was dismissed. Raw API responses, full advisory ranges, physical package inventory and scans are retained at `C:/Users/Anup/.codex/security/volitex-20261022`; [evidence hashes](evidence/dependency-reconciliation-2026-10-22.json) identify the inputs.

Baseline: release `1ea83b0832faeafbbf867496b69f75f6a992ffb8` and the four runbook/kit image digests. The running n8n container uses that exact digest. Version matching uses every npm branch from the primary GitHub advisory API, normalizing comma-separated comparators to whitespace and checking ecosystem explicitly. A historical alert's single version branch is insufficient for comparing a different installed major version.

| Manifest | Alerts | Production relationship |
| --- | ---: | --- |
| deployment/n8n/npm-candidate/package-lock.json | 154 | Rejected n8n 2.43.5 assessment; not consumed by maintained Dockerfile or Compose; excluded from Inbox build context |
| pnpm-lock.yaml | 43 | Browser/build/test graph; node_modules removed from final image, but browser dependencies remain in compiled assets |
| package.json | 2 | markdown-it runtime and Vitest development declarations |
| tests/playwright/package.json + pnpm-lock.yaml | 18 | Separate test project |
| deployment/n8n/hardened/package.json + package-lock.json | 2 | Hono in the maintained overlay |
| Gemfile.lock | 2 | Devise, existing dispositions below |

## Critical alerts and existing resolutions

Nine Critical alerts from the historical assessment concern Handlebars, argv-parser, simple-git, expr-eval, tar, fast-xml-parser and form-data. Comparing physical maintained-image versions with the complete advisory ranges finds **zero matching Critical advisories from this snapshot**. This does not approve the rejected recipe or future advisories.

The other two Critical alerts are tinypool test-tool findings (`GHSA-5gmw-xhrv-c9v3`, `GHSA-85c8-ppgw-ccpr`). They are absent from production runtimes and remain open development risks. A compatible test-runner migration is separate work; do not execute untrusted test configurations or fixtures with production credentials. Separate Playwright and other build-tool findings likewise remain visible in the CSV; they are not dismissed or silently upgraded across incompatible majors.

Many historical High alerts concern versions already replaced or absent, including Handlebars 4.7.10, Nodemailer 10.0.9, simple-git 4.0.1 and argv-parser 2.0.1. Each advisory remains individually recorded. The braces 3.0.3 High finding remains in raw scans and is resolved only by the existing independent source-hash verifier and behavioral regressions. No new audit ignore or scanner suppression was added.

Both Devise Medium alerts already have specific dispositions: User forces unconfirmed_email dirty tracking before regenerating the confirmation token, and User/SuperAdmin do not enable Timeoutable. Existing `spec/models/user_email_reconfirmation_security_spec.rb` covers both. `.bundler-audit.yml` explains the exceptions. Devise 5 conflicts with current authentication dependencies; this change does not force an authentication overhaul.

## Actionable release fixes

The fresh published n8n scan reports **0 Critical, 10 High, 17 Medium, 3 Low and 2 Unknown** findings. One High is the existing braces backport; nine require remediation: MCP SDK (two), MCP server (two), follow-redirects (four physical occurrence/advisory findings), markdown-it (one). follow-redirects is a new finding outside the original GitHub snapshot. October 20 scan clearance cannot approve a new deployment today.

| Component | Published version | Target | Purpose |
| --- | --- | --- | --- |
| Inbox markdown-it | 14.3.1 | 14.3.3 | Browser rendering algorithmic denial of service |
| Inbox Vite | 6.4.3 | 6.4.4 | Build/dev advisories and production audit through plugin peer graph |
| n8n MCP SDK | 1.31.0 | 1.32.0 | Validation/resource exhaustion fixes |
| n8n MCP server | 2.0.0 | 2.3.0 | Validation/resource exhaustion fixes |
| n8n follow-redirects | 1.16.0 | 1.16.1 | High redirect advisories |
| n8n markdown-it | 13.0.2 | 14.3.3 | Available parser fixes |
| n8n Hono | 4.13.7 | 4.13.11 | Static-prefix authorization bypass |
| n8n sanitize-html | 2.17.7 | 2.18.1 | Available sanitizer fixes |

The [MCP upstream advisory](https://github.com/advisories/GHSA-46jr-4wx8-v453) explicitly says upgrading alone does not enable optional input limits. The shared HTTP/JSON production policy therefore disables both `mcp` and `mcp-registry` backend modules; the actual module-registry probe asserts they are ineligible. MCP nodes are already excluded. Future MCP enablement requires explicit caller review, `maxToolInputElements` and transport/parser body limits with adversarial acceptance. Existing client HTTP workflows do not require MCP.

New packages use the existing integrity-locked complete dependency overlay and fail when upstream versions change. The updated Inbox production JavaScript audit reports **zero findings at all severities**. Built-image tests, fresh scans, all four exact-source candidate/migration/campaign/full CE gates and actual publication remain required before replacement digests can be used. A local candidate or green workflow title alone does not prove publication.

## Full image scan follow-up

Fresh scans of the old Inbox, n8n PostgreSQL and Valkey images found no High/Critical findings. Inbox retains the two explained Devise Medium findings and a json 2.9.1 Low finding. All four images also contain the newly reported musl `CVE-2026-107891`, classified UNKNOWN by this scanner, with available Alpine patches. UNKNOWN is not treated as harmless: the three maintained n8n-family Dockerfiles now explicitly install musl/musl-utils 1.2.6-r3, and Inbox's existing targeted OS upgrade includes musl, musl-dev and musl-utils on Alpine 3.23. The [Alpine record](https://security.alpinelinux.org/vuln/CVE-2026-107891) is the vendor source. Fresh built-image scans must confirm removal. No broad OS/distribution upgrade is included.

## Separate Inbox database prerequisite — newly confirmed blocker

The compatibility-only pgvector digest in the old runbook has **16 Critical, 116 High, 229 Medium, 185 Low and 10 Unknown** raw findings. Current vendor `pg16-trixie` was also assessed and still has two Critical and 87 High findings. These counts describe package findings, not proof every advisory is remotely reachable; neither image is approved by our no-unresolved-Critical/High release policy.

`deployment/production/InboxPostgres.Dockerfile` therefore keeps PostgreSQL 16 and the separate Inbox database architecture, builds pgvector 0.8.7 from a checksum-verified upstream archive against immutable official PostgreSQL 16.15/Alpine 3.24, disables host-native CPU optimizations, and uses the existing maintained companion pattern to remove obsolete gosu and apply vendor security patches. Build tools remain in a separate build stage. No existing database or volume is migrated. Candidate and publication now scan, archive, source-verify and publish this fifth image; application boot, database dump/restore and the full Inbox/n8n acceptance must run against it. Until those gates pass and its digest is published, the complete deployment remains blocked. Never mount existing Debian PGDATA into the Alpine replacement; use logical restore into fresh storage.

## Acceptance failure and startup readiness

Interim source `29d885f389` failed the ordinary production-reply acceptance assertion after its other recovery checks. It was not approved. Bounded failure diagnostics now retain provider counters and execution/node outcome enums, never raw events, headers or credentials. The actual n8n server marks readiness before workflow initialization; the harness previously resumed Inbox delivery based only on that general readiness endpoint. A new deliberately invalid-signature probe requires HTTP 401 from the real guarded workflow and queue worker before resuming delivery at activation, upgrade, graph replacement and rollback. Existing exact reply-count, duplicate, ownership, failure and recovery assertions are unchanged. The previous timeout's specific cause remains subject to execution evidence; the readiness limitation itself is confirmed by the inspected runtime startup order. Final release acceptance must pass with this stronger barrier.

## Kit decision and KVM handoff

The old kit is still an integrity-verified historical snapshot. Its images require security updates and a new verified kit before go-live. Reuse Compose topology, provisioning, WhatsApp effective-secret instructions and operational acceptance procedures. No production server, credentials, client data or paid resources were changed by this reconciliation.

The founder purchases KVM 4, selects the supported OS/region, retains provider-console recovery/billing access, supplies public IP and approved SSH access, and completes owner-only identity/MFA/client-consent steps. Codex performs host hardening, operator provisioning, Docker/Coolify, firewall, DNS and application setup wherever access is available.

Deployment prerequisites: domain/DNS control; separate private Inbox pgvector PostgreSQL/Valkey resources provisioned on the KVM; n8n's separate PostgreSQL/Valkey from Compose; protected application/Active Record/n8n encryption keys and DB/queue passwords; SMTP; Meta App/business/WABA/phone credentials; per-client Google/CRM/calendar OAuth if contracted; durable media storage; encrypted off-server backup destination/decryption identity; alert destination and independent monitoring/escalation. S3 media storage is optional; LLM credentials are required only for workflows that call an LLM. Preserve exact encryption keys for recovery. Never put secrets in chat or Git.

After access: inspect host state; verify approved release/kit; secure host/private services; configure protected secrets/effective settings; migrate/deploy; connect scoped client integrations; verify text/media, tenant isolation, human handoff and workflow failures; exercise off-server restore/reboot/queue recovery and alerts; measure headroom; obtain client acceptance. Campaigns remain separately gated. Configure persistent health/backup schedules, alert routing, maintenance records and responder escalation; an open chat does not provide continuous incident response. Production deployment, credential changes, destructive recovery and extra spending require appropriate authorization.
