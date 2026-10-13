# Production candidate verification — 2026-10-13

## Decision

**NOT READY — SPECIFIC BLOCKERS REMAIN.** The Inbox candidate is built and verified for isolated staging. Unresolved n8n runtime vulnerabilities, red baseline-wide CI, live integration access, and first-server acceptance prevent a first-client release. No production deployment, image publication, DNS/callback change or live WhatsApp send occurred.

## Candidate and environment

- Application commit: `7b0f621bda92e1a5b63ff766363ef115c4b32a46`, branch `codex/whatsapp-interactive-quick-menus`.
- Local immutable OCI index: `sha256:738a781502d50ff803f6ac4f0387f0952a4612b9fbca0c722db04cd920261c26`. Image: `volitex-candidate:7b0f621bda92e1a5b63ff766363ef115c4b32a46`. Unpublished; this is not a registry release digest.
- Exact Git archives were build inputs. Uncommitted runbook/audit documentation was excluded. Original feature commits and all other worktrees remain intact. The primary master checkout and its unrelated dirty files were preserved.
- Docker client/server 29.8.0; Compose 5.5.1; WSL 2.6.1. Inbox Ruby 3.4.11, Node 24.21.0 and Ruby zlib gem 3.2.3 verified. Native checks additionally use isolated Ruby 3.4.11/Bundler 2.5.16/PostgreSQL 18; hosted migration checks use PostgreSQL 16.
- Existing local Inbox/n8n services remained running and healthy after the recovered Docker environment. Temporary probe containers were removed; volumes were retained. No factory reset or volume prune/delete was performed.

## Results

| Gate                    | Result and evidence                                                                                                                                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Exact application build | PASS, local candidate above; native compilation, production Vite assets and export completed. Compatible patched Vite 6.4.3 used.                                                                                                                           |
| Production boot         | PASS, web/Sidekiq, health/API/login, DB/Redis, Quick Menu schema and worker registration. Restart and graceful stop passed.                                                                                                                                 |
| Persistence and restore | PASS, shared attachment volume read from a separate container and retained after restart; custom PostgreSQL dump restored into a separate disposable database. Not an off-server disaster-recovery test.                                                    |
| Startup validation      | PASS, a container missing encryption keys exited nonzero before runner execution and named the missing keys.                                                                                                                                                |
| Application image scan  | PASS HIGH/CRITICAL gate: 0 critical, 0 high. Full inventory: 2 medium Devise version flags with tested mitigations, 1 low unselected default-JSON flag. No scanner findings suppressed.                                                                     |
| Backend focused         | PASS, 237 examples locally, including complete messages-controller coverage and two new Devise mitigation examples. Hosted focused verification at `1395baffbc`: 203 + 5 + 4 = 212 examples.                                                                |
| Migrations              | PASS, hosted fresh migration/schema dump, upgrade from `452f849`, foreign key/index/two check constraints, Quick Menu down/up; production prepare passed in the actual candidate image.                                                                     |
| Frontend focused        | PASS, 5 Quick Menu/clipboard/realtime files, 16 tests. Full suite includes the bubble/helper/widget tests.                                                                                                                                                  |
| Full local frontend     | FAIL, 3,790 passed / 33 failed. Fourteen additional failures were timezone-dependent; all five affected files passed under CI's UTC timezone (113 tests). No assertions or snapshots weakened.                                                              |
| Full hosted frontend    | FAIL, 3,804 passed / 19 failed; same baseline theme/appearance failure headings.                                                                                                                                                                            |
| Full hosted backend     | FAIL, 6,038 examples / 34 failures / 2 pending. Zero unmatched failed descriptions against the actual recorded base artifacts. Baseline reproduction is not acceptance of those behaviors for launch.                                                       |
| Repository lint         | FAIL, RuboCop 2,105 files / 2,088 offenses; ESLint 260,063 problems. Changed Ruby files passed normal rules; no blanket disables added.                                                                                                                     |
| Ruby audit              | PASS with two explicit tested Devise exceptions. Audit with no ignores reports exactly those two medium advisories. Obsolete Rails/Azure exceptions were removed, and the narrowed policy passed.                                                           |
| JavaScript audit        | FAIL, production graph 0 critical / 3 high / 10 moderate / 5 low; full graph 2 critical / 34 high / 30 moderate / 8 low. Remaining critical Tinypool is test-only; remaining production-graph highs are build/SSR tooling, not a deployed Node SSR service. |
| n8n queue               | PASS on isolated stable 2.42.7 candidate: worker absence prevented completion, worker startup completed the synthetic webhook and database execution. Its volumes were retained. Not a signed Inbox-to-n8n-to-reply test.                                   |
| Live Meta/WhatsApp      | BLOCKED, separate verified test account/recipient/app resources, fresh protected token and specific send approval are missing. Old compromised token was not reused. Heroku App Review and its callback remained unchanged.                                 |
| KVM 4 operations        | NOT RUN, server not purchased/deployed. TLS/networking, SMTP/object storage, reboot recovery, encrypted off-server restore, monitoring alerts, load/headroom and first-client acceptance remain pending.                                                    |

Hosted evidence:

- [Starting commit migration/focused verification](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38345725397).
- [Starting commit candidate build/boot/scan](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38345728400).
- [212-example updated focused verification](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38348697492).
- [Final candidate build/boot/scan](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38350478281).
- [Final full CI](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38350478279).

Public visibility restored GitHub job execution; no payment/spending setting was changed. Initial retry `38343982000` still failed before jobs started. Later runs actually executed.

## Fixes and files

- `package.json`, `pnpm-lock.yaml`: resolved same-major security patches for Vite, glob, picomatch, brace-expansion, PostCSS, nanoid and source-map-js. Production high findings reduced from 23 to 3. Lockfile generated through pnpm, not manually version-edited; formatting normalized.
- `docker-compose.production.yaml`: shared persistent `/app/storage` volume across application services, preserving local attachments during replacement. S3 remains the intended runbook configuration.
- `script/production/verify_candidate.sh`: shared storage, PostgreSQL dump/restore and persistence checks; retains volumes.
- `script/production/verify_n8n_queue.sh`: optional candidate image argument and volume-preserving cleanup. Existing deployment image/configuration was not changed.
- `app/controllers/concerns/api/v1/accounts/quick_menu_sending.rb`, sending request spec: reproduced numeric-prefix menu and conversation IDs being accepted; strict positive-ID validation now returns structured 422 without creating a message. Each regression failed before the fix, then passed.
- `docker/Dockerfile`: upgrades OS zlib to the fixed 1.3.2-r1 revision without changing Ruby/framework versions. Compression roundtrip and full post-fix scan passed.
- `spec/models/user_email_reconfirmation_security_spec.rb`: verifies the existing backport keeps pending email/token paired across stale concurrent updates, with a nonempty token; verifies User/SuperAdmin do not enable Timeoutable.
- `.bundler-audit.yml`: removes obsolete exceptions; retains only the two verified Devise mitigations.
- First-client runbook: storage durability, AOF settings, password-safe CLI example and explicit n8n release stop. Verification report and advisory CSV record evidence.

## Security disposition

Pinned n8n 2.40.3 (`e397d0aa…`) scan: **32 critical / 79 high package findings**. Tested stable 2.42.7 (`sha256:906dd7fb0a2f23869001d1767168359489c518ff34d4f67427abf2dc59e868fe`): **13 critical / 72 high**. It removes the vm2 critical findings, but still includes critical OpenSSH, simple-git/argv-parser, Handlebars, proxy-addr and shell-quote findings. Counts include repeated OS package findings, not distinct exploitable CVEs. Workflow/editor access and selected node paths affect reachability; production workflow reachability has not been cleared. Major simple-git replacement and ad-hoc mutation of the vendor image were not forced. Obtain a compatible upstream or reviewed source-built remediation and verify it before release. Neither tested n8n image was promoted or its production pin replaced.

The Inbox scan's Devise race flag is mitigated by the existing `unconfirmed_email_will_change!` backport; its timeout redirect flag is not reachable because Timeoutable is disabled. See [upstream advisory](https://github.com/advisories/GHSA-57hq-95w6-v4fc) and [timeout advisory](https://github.com/advisories/GHSA-jp94-3292-c3xv). Tests verify both claims. The low JSON finding is the physical default gem 2.9.1; the application actually loads patched JSON **2.21.2** under Bundler. Flags remain visible in the full inventory.

Default-branch GitHub alerts currently total 162 (6 critical / 83 high / 62 moderate / 11 low); this is not the candidate graph. Two open historical secret alerts concern Mapbox (2019) and Slack (2023). Exact-value comparison found no current source match; validity remains unknown. Issuer/revocation confirmation is still required. Values were never printed, committed or used to authenticate.

## Commands and retained evidence

```sh
git archive --format=tar --output=<temporary-archive> 7b0f621bda92e1a5b63ff766363ef115c4b32a46
docker build --file docker/Dockerfile --build-arg GIT_SHA=7b0f621bda92e1a5b63ff766363ef115c4b32a46 --tag volitex-candidate:7b0f621bda92e1a5b63ff766363ef115c4b32a46 - < <temporary-archive>
bash script/production/verify_candidate.sh volitex-candidate:7b0f621bda92e1a5b63ff766363ef115c4b32a46 7b0f621bda92e1a5b63ff766363ef115c4b32a46
bash script/production/verify_n8n_queue.sh n8nio/n8n@sha256:906dd7fb0a2f23869001d1767168359489c518ff34d4f67427abf2dc59e868fe
pnpm audit --prod --json
pnpm audit --json
pnpm run test:coverage --maxWorkers=2 --minWorkers=2 --reporter=default --reporter=json --outputFile=<temporary-report>
pnpm exec prettier --check package.json pnpm-lock.yaml docker-compose.production.yaml
```

Trivy 0.75.0 immutable tool digest: `sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa`. Executed `image --scanners vuln --severity HIGH,CRITICAL --exit-code 1` gates and separate full-severity JSON inventories. Exact Ruby commands and logs are retained in the local temporary `volitex-final-security-verify.sh` / `.log` files; rbenv initialized, isolated gem path, unseeded disposable database and test-only encryption keys used. Source/archive parity was checked before reusing the faster Linux copy. The initial Windows-mounted backend attempt was canceled before examples for I/O latency; it was not called a pass.

Logs/JSON: `volitex-final-7b0f-build.log`, `volitex-final-7b0f-boot.log`, `volitex-resumed-image-audit`, `volitex-final-7b0f-ci-rspec`, `volitex-final-7b0f-ci-failures.log`, `volitex-final-security-verify-complete.log`, `volitex-resumed-full-frontend.json`, `volitex-resumed-timezone-regression.log`. No production data included. Test-generated snapshot line-ending changes were discarded; no assertions changed.

Deployment command remains `RAILS_ENV=production bundle exec rails db:chatwoot_prepare`; upgrades can use `db:migrate`. Back up data and retain encryption keys first. Quick Menu reversal drops saved menus; the n8n uniqueness repair is intentionally irreversible. The logical restore test does not replace encrypted off-server, object-store or KVM disaster-recovery validation.

## Next release gates

1. Compatible n8n critical/high remediation with image and queue/workflow regressions.
2. Explicit disposition/remediation of baseline-wide CI failures and lint debt; no suite is declared green.
3. Fresh protected test credentials, isolated Meta app/callback and verified recipient; approve the exact live test in the [existing isolated test proposal](isolated-whatsapp-verification.md).
4. After pre-deployment gates pass, perform actual KVM 4 operational acceptance. Preserve the shared multi-tenant architecture; no extra recurring infrastructure is proposed. A single VPS has no zero-downtime failover guarantee.

Delivery note: the application candidate above is frozen at its tested code commit. The subsequent verification/audit-policy commit changes only the runbook, audit exceptions and evidence files; it is not represented as a newly built application artifact. The release owner must use the recorded candidate or verify any later image separately.
