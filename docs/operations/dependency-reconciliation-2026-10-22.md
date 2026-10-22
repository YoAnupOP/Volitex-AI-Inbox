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

## Kit decision and KVM handoff

The old kit is still an integrity-verified historical snapshot. Its images require security updates and a new verified kit before go-live. Reuse Compose topology, provisioning, WhatsApp effective-secret instructions and operational acceptance procedures. No production server, credentials, client data or paid resources were changed by this reconciliation.

The founder purchases KVM 4, selects the supported OS/region, retains provider-console recovery/billing access, supplies public IP and approved SSH access, and completes owner-only identity/MFA/client-consent steps. Codex performs host hardening, operator provisioning, Docker/Coolify, firewall, DNS and application setup wherever access is available.

Deployment prerequisites: domain/DNS control; separate private Inbox pgvector PostgreSQL/Valkey resources provisioned on the KVM; n8n's separate PostgreSQL/Valkey from Compose; protected application/Active Record/n8n encryption keys and DB/queue passwords; SMTP; Meta App/business/WABA/phone credentials; per-client Google/CRM/calendar OAuth if contracted; durable media storage; encrypted off-server backup destination/decryption identity; alert destination and independent monitoring/escalation. S3 media storage is optional; LLM credentials are required only for workflows that call an LLM. Preserve exact encryption keys for recovery. Never put secrets in chat or Git.

After access: inspect host state; verify approved release/kit; secure host/private services; configure protected secrets/effective settings; migrate/deploy; connect scoped client integrations; verify text/media, tenant isolation, human handoff and workflow failures; exercise off-server restore/reboot/queue recovery and alerts; measure headroom; obtain client acceptance. Campaigns remain separately gated. Configure persistent health/backup schedules, alert routing, maintenance records and responder escalation; an open chat does not provide continuous incident response. Production deployment, credential changes, destructive recovery and extra spending require appropriate authorization.
