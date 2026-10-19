# Restricted n8n profile assessment — 2026-10-19

Status: selected for the restricted pre-client deployment package after caller/policy and full built-image acceptance. Overall release acceptance remains pending exact-source CI, application registry publication and actual server gates. This is not a global security clearance or a production deployment approval.

Candidate: official 2.43.8, `n8nio/n8n@sha256:a18edcf018198b33b5488fb47ededafe11e0b10d28f65b9535b7c447c9ce3b2c`.

## Scope

Private operator-only editor, no customer n8n users, no public router/host port; dedicated internal automation bridge reachable only by ordinary Inbox Sidekiq and n8n main. Main/worker load the same versioned 18-type HTTP/JSON policy. No untrusted workflow authors, custom packages or filesystem mounts. Provider access uses HTTP APIs. Changing these conditions requires a new review.

## Scan evidence

Trivy 0.75.0, identical database for 2.43.7 and 2.43.8, no suppression: both 11 critical, 35 high, 93 medium, 27 low, 1 unknown. All finding identity/package/version/severity tuples matched. Database SHA256: `779fd16c84f076757a8b4b72c3c81004ba6b91a95773417ba1c98a671dd2940a`.

These dependencies remain in the image. Restrictions reduce reachable callers; they do not patch the packages. The historical inventory retains all 132 rows and adds candidate/profile evidence without deleting original decisions.

## Caller boundaries inspected

| Dependency path | Enforced boundary / evidence | Limit |
| --- | --- | --- |
| Git/simple-git/argv parser | Source-control and promotions modules ineligible; Git/SSH/Code/shell node resolution rejected | Operator shell/CLI remains trusted |
| TOML/Snowflake SDK | Snowflake node and tool excluded; SDK/TOML absent from require cache after loading allowed types | Not approval for Snowflake |
| TIFF/GraphicsMagick | EditImage excluded; gm absent after allowed-type loading | Do not add image processing without review |
| Native SSL/Expat/PCRE | Inspected OS consumers include Git and native tools; Node ELF does not link these system libraries; Kafka native addon excluded | Native tools still installed; no unrestricted execution |
| OpenSSL QUIC server advisory | Application roles use HTTP/TCP and do not configure a QUIC server | No global OpenSSL remediation claim |
| Handlebars | Actual core mailer uses UTF-8 template strings; fixed core render templates; no permissive prototype flags in inspected engine | No user-provided AST/options/templates |
| Nodemailer | Actual core mailer forwards selected fields, fixed attachment; actual DTO email shapes tested against address lists/free text | No customer editor accounts, fixed SMTP sender, mail node excluded |
| Braces/micromatch | Inspected core glob patterns are fixed package/assets paths; telemetry proxy has no customer-controlled pathFilter pattern | Trusted extension/package paths only |

The runtime probe resolves every allowed type through the actual installed execution registry, rejects blocked types/tool aliases, checks module eligibility, checks mail DTO shapes, and verifies forbidden dependency imports are absent after loading allowed nodes. Core caller tests exercise mailer/rendering boundaries independently. This supports the stated profile only.

## Remaining acceptance

The corrected full run passed on application source 24be9585e9a0b6366dab4db6b938b19191859a79, with acceptance harness source 1e36d1fb57cde8375d7942499b0c4a6d3599ef5e: ordinary signed customer reply, upgrade/restore, interrupted-effect duplicate safety, queued recovery and human takeover. Exactly six intended provider effects. [Safe evidence](evidence/n8n-acceptance-24be9585e9-2026-10-19.json). The workflow update stops all writers, publishes offline and checks the active-version graph before resuming delivery. All 46 candidate critical/high identities match the retained inventory and their profile prerequisites/caller boundaries above. `N8N_IMAGE` now selects this tested digest for this profile only. Obtain final remote CI results and a transport-capable registry artifact before overall release. Actual VPS acceptance additionally requires tunnel/browser login, independent alerts, off-host backup restore, provider credentials and client-specific booking/CRM idempotency. None of those live checks is implied by local synthetic results.
