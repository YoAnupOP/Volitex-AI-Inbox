# Production candidate verification — 2026-10-13

## Latest continuation — localhost ready, production blocked

This section supersedes the earlier candidate below. **NOT READY — SPECIFIC BLOCKERS REMAIN.** The corrected application and isolated localhost/ngrok ingress are ready for operator configuration. No Meta credential was used, callback changed, live message sent, production image published or production service deployed.

### Exact artifacts and delivery

- Tested application source: `38229d6009cac43c86066296275ae629fd5b0d9e`, `codex/whatsapp-interactive-quick-menus`.
- Local image: `volitex-candidate:38229d6009cac43c86066296275ae629fd5b0d9e`; immutable local OCI index/image identity `sha256:65ed1483496563f13add97de1970e415e20dd43b8229a97e221db06b6218b65b`. Unpublished, not a registry release digest.
- n8n evaluated: official stable `2.43.4`, `n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c`. The production example pin was not promoted.
- Original HEAD and remote were clean/matched at `87ff702432b75ed088ce1cceafd3620889f8b4b0`. All existing worktrees and the dirty primary checkout were preserved. Fixes were pushed normally; original feature history remains.
- Commits: `ff7ccc4191` provisioning defaults; `6bdb033aaa` batched campaign audiences/capacity probe; `f31b8f12bc` scopes provisioning to Super Admin; `38229d6009` n8n recovery probe. The first global provisioning attempt introduced five failures and was corrected, not concealed. `6bdb033aaa` is superseded and must not be deployed.
- Subsequent report/inventory commits are metadata only. The executable application source is frozen at the tested SHA above; use that artifact rather than claiming later metadata HEADs were rebuilt.

### Verification checklist

| Gate | Result | Actual evidence |
| --- | --- | --- |
| Source/remote provenance | PASS | Clean expected branch and matching remote before edits; non-force pushes; Git archives used for builds |
| Super Admin provisioning | PASS | Missing default record reproduced: 4 examples, 1 failure before fix; scoped fix, installation overrides, existing tenants, membership and authorization covered |
| Focused backend/regression | PASS | Final 480 examples, 0 failures; includes Quick Menus, webhook signatures/duplicates, ownership/handoff, encryption, deletion, providers, inbound selections, campaign specs, platform accounts, assignment and mailers |
| Focused frontend | PASS | Final 5 files, 15 tests passed; message bubbles, menu helper/picker and settings |
| Full backend | FAIL — baseline matched | 6,042 examples, 34 failures, 2 pending; all 34 identities match actual base-run artifacts (79 distinct failures from two base runs); no unmatched failure after correction |
| Full frontend | FAIL — baseline matched | 3,804 passed, 19 failed, 393 files; same documented theme/appearance failures |
| Changed Ruby/shell/whitespace | PASS | Normal RuboCop: 7 files, no offenses; `bash -n` queue probe; `git diff --check`; no lint rules blanket-disabled |
| Repository lint | FAIL | Ruby 2,107 files / 2,086 offenses; ESLint 260,063 problems. Existing baseline debt; not represented as green |
| Ruby dependency audit | PASS with documented exceptions | Configured `bundle-audit check --update`: no unexcepted findings; raw Devise findings and mitigations remain documented below |
| JavaScript dependency audit | FAIL | Production graph: 0 critical / 3 high / 10 moderate / 5 low; all graph: 2 critical / 34 high / 30 moderate / 8 low; unchanged lockfile |
| Application build/boot/recovery | PASS | Exact Git archive build; web/Sidekiq, assets, health, PostgreSQL/Redis, migrations, shared storage, dump/restore and graceful restart verified locally and candidate CI |
| Application vulnerability scan | PASS high/critical gate | Exact final image: 0 critical / 0 high / 2 medium / 1 low; Devise mitigations and dormant default JSON described below |
| n8n boot/queue/recovery | PASS — synthetic only | Worker absent request waits; main + separate worker process webhook; persisted execution count survives main/worker/PostgreSQL/Valkey restart |
| n8n security | FAIL | 2.43.4 still 13 critical / 72 high / 112 medium / 29 low / 1 unknown package findings; full high/critical inventory attached |
| Public history/secret review | FAIL — unresolved historical findings | All local reachable refs: 23,989 commits / 652.71 MB / 136 potential findings; not 136 confirmed live credentials. 104 test/document/generated paths, 32 others; GitHub historical Slack/Mapbox issuer status remains unknown |
| Newly delivered source secrets | PASS | Four delivered code commits / 24.91 KB: no Gitleaks findings; scan redacted |
| Application image secret scan | REVIEWED, not zero | Five vendor examples: four AWS SDK JWT documentation matches and web-push test private key; no finding in application source. Historical/provider revocation is a separate gate |
| Localhost/ngrok ingress | PASS | Health `woot`; Super Admin sign-in and authenticated new-account form; HTTPS tunnel `/app/login` 404 and unsigned callback POST 401 |
| Meta challenge with real channel | BLOCKED | Channel/app secret and verify token not configured; request specs cover valid challenges and signatures |
| Actual WhatsApp delivery/selections | NOT RUN | Operator will configure fresh credentials and test channel; recipient and explicit send approval still required |
| Complete Inbox/n8n/Meta flow | BLOCKED | No approved live target or configured production HMAC/idempotency workflow; the two-node queue probe does not prove this flow |
| Synthetic campaign sizes | PASS — limited scope | 1k/2k/5k/10k existing campaign job, mocked provider, exact unique recipient counts and duplicate campaign trigger checked |
| Campaign retry/restart/delivery ledger | BLOCKED — implementation gap | One campaign job, no durable recipient ledger; send failures caught and campaign marked completed; crash can leave processing status. No per-recipient recovery/delivery-state proof |
| Actual KVM operations | NOT RUN | No VPS purchased/deployed; reboot, off-server restore, monitoring alerts, SMTP/storage and capacity acceptance remain server-specific |

CI: [final candidate pass](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38392523906), [full suite, red](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38392523880), [final-source migration compatibility pass](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38394398263). Public Actions actually executed; no billing settings were changed.

### Changes and provisioning boundaries

- `app/controllers/super_admin/accounts_controller.rb`: Super Admin create-only fallback to enabled `config/features.yml` defaults when the installation record is absent. Explicit feature selections and configured installation defaults remain authoritative. Updates and other account creation APIs keep their prior behavior.
- `spec/requests/super_admin/account_provisioning_spec.rb`: defaults, overrides, unchanged existing accounts, no implicit account membership, administrator/unauthenticated rejection.
- `app/services/whatsapp/oneoff_campaign_service.rb`: `find_each` bounds audience loading; account-scoped label query and template/provider contract preserved.
- `script/production/specs/campaign_capacity_spec.rb`: explicitly invoked disposable-database benchmark, real template processors, mocked provider boundary, exact counts and repeated trigger. Scoped bulk-fixture lint exceptions are explained; production validations are unchanged.
- `script/production/verify_n8n_queue.sh`: execution persistence and graceful stack restart assertions.
- Runbook/isolated verification docs and three CSV inventories: actual deployment/setup instructions and measured results. Ruby files touched were normalized to LF for normal lint. `Featurable` was restored to its original behavior after CI exposed the global-change regressions.

Existing local installation defaults were present and already enabled the usual management/channel/API features. The proven defect is the missing-record Super Admin path; do not infer that unknown installation overrides should be overwritten. Account creation and assigning an administrator are separate supported Super Admin operations. WhatsApp campaigns remain disabled by default in the authoritative feature list; they were explicitly enabled only in disposable tests. No premium Captain defaults were invented.

### Campaign measurements and limits

Final native run, Ruby 3.4.11/PostgreSQL 18 on WSL, one synchronous ActiveJob test-adapter job per campaign, mocked provider, batched contacts; concurrent local services/builds were present. Docker has 16 virtual CPUs and about 12.38 GB memory; this is not KVM 4 capacity evidence. Fixture insertion is bulk synthetic setup, not customer onboarding. Peak RSS is cumulative for the test process, including preceding specs.

| Recipients | Enqueue ms | Processing s | Recipients/s | Peak process RSS KiB | Account-read p95 ms |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | 3.45 | 1.358 | 736 | 413,440 | 1.186 |
| 2,000 | 3.47 | 0.534 | 3,749 | 414,976 | 1.332 |
| 5,000 | 3.12 | 1.302 | 3,839 | 415,616 | 1.347 |
| 10,000 | 4.66 | 2.640 | 3,788 | 418,048 | 1.474 |

The authoritative exact final values are in [campaign-capacity-2026-10-13.csv](campaign-capacity-2026-10-13.csv), including CPU time and database bytes; use that CSV if rounding differs. Each case asserted all recipients processed exactly once, no duplicate on a repeated completed-campaign trigger, and successful campaign status. No real provider calls occurred. Queue-wait p50/p95/p99, actual Sidekiq/Redis backlog, CPU percentage peak, connection exhaustion, concurrent HTTP/human latency, fault injection and killed-worker recovery were not measured. A synchronous test adapter cannot establish those gates. Safe bulk campaign recovery requires a separately scoped durable recipient state/retry design; do not enable paid bulk messaging based on this benchmark. Interactive in-window menus do not establish template-campaign eligibility or Meta throughput.

### Security disposition

n8n stable 2.43.4 is **not approved**. Material critical packages include OpenSSH 10.3_p1-r0 (fixed r1), simple-git 3.36.0 (fixed 4.0.1), argv-parser 1.1.1 (fixed 2.0.1), handlebars 4.7.9 (fixed 4.7.10), proxy-addr 2.0.7 (fixed 2.0.8), shell-quote 1.9.0 (fixed 1.11.0). They are physically in the runtime image. No SSH daemon is intentionally started, but that alone does not dispose of clients or JavaScript runtime exposure. The hardened official image has no available `apk` executable; arbitrary in-place package surgery was not used. Upstream 2.44.0 prerelease still declares vulnerable handlebars 4.7.9, so a prerelease is not an established fix. A vendor-patched release or properly resolved/source-built and fully regression-tested candidate is required; major git-library overrides without compatibility evidence are not accepted.

Current default-branch Dependabot: 162 open (6 critical, 83 high, 62 medium, 11 low), distinct from the candidate artifact. App source audit retains build/test graph findings; production image excludes Node dependency trees and test tools. Existing Devise backport/disabled Timeoutable and loaded JSON 2.21.2 remain covered by focused tests. No dependency versions were changed in this continuation.

History findings are redacted metadata only in [public-history-secret-finding-metadata.csv](public-history-secret-finding-metadata.csv). Fixture/generated matches require classification, not blanket dismissal. Historical Slack and Mapbox alerts need issuer-side revocation evidence; no history rewrite or alert closure occurred. The operator confirmed the newly pasted Meta token was revoked; this is operator confirmation, not issuer API verification. It was never reused. No passwords/tokens are included in these reports.

### Local setup and next live gate

- Inbox: `http://127.0.0.1:3400`; Super Admin: `http://127.0.0.1:3400/super_admin/sign_in`; n8n: `http://127.0.0.1:5679` (experimental/security-blocked).
- Isolated containers: `volitex-local-staging-20261013-*` and `volitex-n8n-local-staging-20261013-*`. Persistent volumes and independent keys retained. Original eight local services were not restarted/stopped.
- Private WSL setup/credential directory: `/home/anup/.codex/runtimes/volitex-local-staging-20261013` (0700; files 0600). `super-admin-credentials.json` contains a generated local-only login; `demo-credentials.json` is the earlier generated demo login. The demo account was created before the operator requested manual setup; it was retained, not deleted. Use the existing user or another account through Super Admin.
- Operator-started tunnel: `https://e2f2-2402-a00-400-2bc3-bc60-7acd-62d8-cd71.ngrok-free.app`. Callback: that URL plus `/webhooks/whatsapp/+15556686289`. Tunnel lifetime/URL may change. Automatic tool approval rejected launching ngrok; operator started it, and HTTPS reachability was then actually checked.
- Only the callback path is public; UI/API/database/worker endpoints are not exposed. Ngrok request inspection and ingress access logging are disabled. No Meta channel is configured yet. Keep credentials private and enter the matching app secret through the protected environment/configuration before restarting this isolated stack.
- **Important:** saving a manual Cloud inbox invokes existing WABA app subscription and phone-number callback override code. Confirm the target is exclusively the authorized test phone and that redirecting that phone is acceptable before saving. The global Tech Provider App Review callback must remain unchanged. A phone-specific override may be the safer existing mechanism, but actual permissions/current subscription must be checked with fresh protected access first.
- After channel setup, verify the challenge and correctly signed webhook, then obtain recipient confirmation and explicit approval for a small bounded text/button/list test. No live send is authorized by merely creating the inbox. The production HMAC/duplicate/ownership workflow still needs configuration and full integration verification.

Commands: exact archive `docker build --file docker/Dockerfile --build-arg GIT_SHA=38229d6009cac43c86066296275ae629fd5b0d9e --tag volitex-candidate:38229d6009cac43c86066296275ae629fd5b0d9e - < archive.tar`; `bash script/production/verify_candidate.sh IMAGE SHA`; `bash script/production/verify_n8n_queue.sh N8N_DIGEST`; `bundle exec rspec script/production/specs/campaign_capacity_spec.rb` with the focused specs; `bundle exec bundle-audit check --update`; `pnpm audit --prod --json`; `pnpm audit --json`; `pnpm exec vitest run app/javascript/dashboard/components-next/message/bubbles/specs app/javascript/dashboard/components-next/quickMenus/specs app/javascript/dashboard/routes/dashboard/settings/quickMenus/specs --maxWorkers=2 --minWorkers=2`; pinned Trivy vulnerability/secret scans and redacted Gitleaks history/delta scans.

Local logs: `volitex-final-narrow-verify.log`, `volitex-final-frontend.log`, `volitex-38229-build-boot.log`, `volitex-38229-scan.log`, `volitex-38229-secret-scan.log`, `volitex-38229-ci-rspec`, `volitex-n8n-2434-recovery.log`, `volitex-staging-login-verify.log`, plus scan JSONs. Deployment migration remains `RAILS_ENV=production bundle exec rails db:chatwoot_prepare`; back up data and preserve encryption keys first. No new migration was added in this continuation.

**Launch decision:** localhost operator setup may proceed. First-client production deployment/onboarding must wait for the n8n security gate, explicit CI debt disposition, full authenticated workflow/live smoke test, and the applicable KVM operational acceptance. Campaign reliability is an additional gate if bulk messaging is sold. No zero-downtime guarantee is made.

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
