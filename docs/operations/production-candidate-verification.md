# Production candidate verification — 2026-10-11

## Release decision

**NOT READY — SPECIFIC BLOCKERS REMAIN.** This record does not authorize production deployment, image publication, DNS changes, purchases, or customer messaging.

The target remains one shared multi-tenant KVM 4 with Coolify, private self-hosted PostgreSQL/Valkey, and a separate n8n main/queue worker. The Vercel/Supabase onboarding portal is unchanged.

## Exact starting state and checklist

- PASS: feature worktree `C:/Users/Anup/.codex/worktrees/whatsapp-quick-menus/Volitex-AI-Inbox` was clean at `84704f96df80f708598360142f90a4d93535e5dd`, matching `origin/codex/whatsapp-interactive-quick-menus`.
- PASS: primary checkout remained master `3e1cc0089c2e0685f348e7000429ecc36ea46b66`; unrelated staged/unstaged changes, deleted files and the untracked n8n workflow were preserved. No other worktrees were reset or cleaned.
- PASS: read the first-client runbook, WhatsApp encryption recovery and n8n control-plane documentation; inspected production Compose, example environment contract, Dockerfile, publish/build/test workflows and application security paths.
- PASS: current GitHub alerts and local JavaScript audits retrieved; hosted Ruby audit executed.
- PASS: narrow dependency resolution, webhook logging fixes and clipboard regression implemented.
- PASS: disposable PostgreSQL 16 fresh migrations, prior-schema upgrade, Quick Menu rollback/reapplication and 208 production-critical examples at `56c45ab1299d8d76bd135523185b88476333fe8b`.
- IN PROGRESS: final full CI and exact-candidate image/boot gate. An earlier image built successfully and booted web/Sidekiq, but failed the fixed-delay restart check; this is not a passed smoke test.
- BLOCKED locally: Docker daemon and Ubuntu WSL execution time out; neither daemon reset nor unrelated service termination performed.
- BLOCKED externally: no explicitly identified authorized test number/account and non-production Meta/n8n environment.
- NOT RUN: production deployment, image publication, live migrations, KVM reboot, backup restore and monitoring alert drills.

## Environment evidence

Host Node `22.14.0`, pnpm `10.2.0`; repository requires Node 24 and hosted CI uses 24. Host Ruby/Bundler are absent. Docker client `29.8.0`, Compose `5.5.1`, WSL `2.6.1.0`, kernel `6.6.87.2-1`. Docker server version probe timed out after 20 seconds; Ubuntu Ruby probe also timed out after 20 seconds. Windows had approximately 180 GB free disk and 8.7 GB free physical memory during diagnostics. These observations do not establish an OOM or disk-exhaustion cause.

Safe recovery requires a maintenance window for local development services: stop their active work, quit Docker Desktop, run `wsl --shutdown`, reopen Docker Desktop, and verify `docker version`/container health. This interrupts every WSL distribution and Docker workload; it was not performed because unrelated Inbox/n8n services could be affected. Do not prune volumes, factory-reset Docker or delete WSL distributions. Hosted non-production CI avoids requiring extra infrastructure.

## Changes and reasons

- Axios `1.15.0` → `1.20.0`: current same-major advisory fixes; browser API clients and authentication requests are relevant.
- Vitest/coverage `3.0.5` → `3.2.6`: patched UI-server arbitrary file execution advisory, keeping the test framework major stable.
- shell-quote override `1.11.0`: fixes current command-injection advisories in the Histoire editor-launch dependency. This is a development/build path.
- ProseMirror view `1.42.6` and model `1.25.12`: patched clipboard attribute validation with compatible, single model identity. An actual clipboard regression caught both duplicate model instances and an incompatible minimum-patch combination; no assertion was weakened.
- js-cookie `3.0.7`: browser cookie prototype-hijack patch.
- linkify-it 5.x override `5.0.2`: markdown renderer scan-loop denial-of-service patch; the separate Histoire 3.x dependency is not forced across a major boundary.
- xmldom 0.8.x override `0.8.15`: patches XML parser injection/resource issues reached through video.js/DASH manifest parsing; remains in the supported 0.8 series.
- Active Job argument logging disabled: arguments include signing credentials and customer messages. Job IDs, timings and execution metadata remain available.
- Webhook failure logs retain job/type/error class, omitting customer payloads, credential-bearing destination URLs and provider response bodies. Instagram refresh errors likewise omit raw bodies/tokens.
- Docker build context excludes Git/worktree metadata and Rails plaintext master/encryption key files.
- Updated vite_ruby to 3.11.1 with its compatible vite-plugin-ruby 5.2.5 and rack-proxy 1.0.3 using Bundler/pnpm resolution. The first unpaired update failed compatibility validation and was corrected.
- HairTrigger 1.3.1 fixes Rails 7.2 schema dumping. The schema was regenerated from the disposable prior-schema upgrade, rather than hand-edited.
- Production startup requires all three Active Record encryption keys and checks installed gems without installing dependencies or logging shell arguments. Asset compilation has a task-specific exemption; runtime has none. Five guard specs and three mocked entrypoint checks pass.
- Added migration `20261011000000` to repair the missing n8n delivery unique index in schema-loaded databases. It refuses duplicates or invalid existing indexes without deleting data. A database uniqueness regression passes. Its down migration deliberately refuses to remove the idempotency protection.
- Runbook identifies its existing immutable master image as historical, removes the stale clean-Ruby-audit claim, and explicitly requires encryption backfill/key retention.
- Added a non-publishing candidate CI gate and disposable verification script. It records exact Git SHA and local image identity, verifies assets/no node_modules/no RSpec gems, uses ephemeral credentials, runs the actual production prepare task, checks web/Sidekiq/DB/Redis, restarts services and stops them. It does not push an image or contact Meta.

## Security disposition

GitHub default branch still has 161 open alerts: 4 critical, 87 high, 60 moderate and 10 low. Those are default-branch findings, not the candidate's resolved graph. No exposed secret values were printed or committed during this execution.

| Package/advisory                                                               | Exposure and reachability                                                                 | Disposition / verification                                                                                                                                                                      |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ProseMirror / GHSA-c8x8-7fp4-3x9w, high                                        | Agent browser editor processes pasted HTML                                                | Fixed; explicit malicious clipboard context regression and editor tests pass                                                                                                                    |
| Axios, multiple high/moderate advisories                                       | Browser API/authentication client; Node HTTP-only advisories have different reachability  | Same-major update resolved by pnpm; message API tests pass; full frontend suite remains a gate                                                                                                  |
| shell-quote / GHSA-w7jw-789q-3m8p and GHSA-pqg4-j6r4-53mv, critical            | Histoire launch-editor; build/development, not a Rails request path                       | Updated to 1.11.0; audit rerun; final image absence must be checked                                                                                                                             |
| Vitest / GHSA-5xrq-8626-4rwp, critical                                         | Test/UI server; normal CI runs no public Vitest UI                                        | Updated to 3.2.6; focused tests pass                                                                                                                                                            |
| Tinypool / GHSA-5gmw-xhrv-c9v3 and GHSA-85c8-ppgw-ccpr, critical               | Vitest worker options; no production Node server or untrusted test configuration intended | Unresolved; 1.x has no published patched version. 2.x override/framework major upgrade requires compatibility testing; not forced. Image excludes node_modules, pending actual build inspection |
| js-cookie / GHSA-qjx8-664m-686j, high                                          | Browser authentication/cookie helpers                                                     | Patched to 3.0.7; API/editor regressions executed                                                                                                                                               |
| linkify-it / GHSA-22p9-wv53-3rq4 and GHSA-v245-v573-v5vm, high                 | Customer markdown rendered in agent browser                                               | 5.x patched to 5.0.2; no cross-major override of Histoire dependency                                                                                                                            |
| xmldom, multiple high advisories                                               | video.js → mpd-parser XML manifests; browser media path                                   | 0.8.x patched to 0.8.15; full browser media/live smoke still required                                                                                                                           |
| ActiveStorage critical default-branch alert                                    | Rails runtime attachment handling                                                         | Candidate already resolves 7.2.3.2; no new Rails upgrade necessary for that alert                                                                                                               |
| rack-proxy / GHSA-42qh-8mx8-7wqm                                               | Ruby bundle includes the Vite development proxy                                           | Fixed to 1.0.3 through compatible vite_ruby 3.11.1/plugin 5.2.5; hosted bundle-audit passes, no ignored advisory                                                                                |
| glob, picomatch, braces, brace-expansion, postcss, source-map-js, nanoid, Vite | Predominantly build/watch/CSS tooling despite some production-manifest classification     | Reachability/image inventory assessment incomplete; braces advisory has no patched release. Trusted builds alone do not clear all advisories                                                    |
| Vue server-renderer                                                            | Transitive Vue SSR package; application is Rails plus browser Vue                         | Server-side rendering path not identified; final artifact inventory and explicit disposition still needed                                                                                       |

Security is not cleared. Counts alone are neither exploitability proof nor an acceptance decision. No risks were silently accepted.

## Executed commands and results

```text
git status --short / git branch --show-current / git rev-parse HEAD
git remote -v / git worktree list / git ls-remote origin <feature-ref>
pnpm audit --json
pnpm audit --prod --json
gh api --paginate repos/YoAnupOP/Volitex-AI-Inbox/dependabot/alerts
pnpm update <named-package>@<fixed-version> --lockfile-only --ignore-scripts
pnpm install --lockfile-only --ignore-scripts
pnpm install --frozen-lockfile --ignore-scripts
pnpm exec vitest run <Quick Menu / message bubble / widget / message API paths>
pnpm exec vitest run <editorHelper / editorContentHelper / clipboard security / message API paths>
pnpm exec eslint app/javascript/dashboard/helper/specs/prosemirrorSecurity.spec.js
pnpm exec prettier --check <new frontend spec and candidate workflow>
bash -n script/production/verify_candidate.sh
git diff --check
gh workflow run run_foss_spec.yml --ref codex/quick-menu-base-verification-20261011
```

Focused feature/widget run after the initial updates: **10 files, 27 tests passed**. Corrected clipboard/editor/API run: **4 files, 132 tests passed**. Initial clipboard test attempts failed (missing jsdom ClipboardEvent, duplicate ProseMirror model, incompatible view/model validation); these were corrected before the passing run. Formatting and new-spec ESLint passed. Missing upstream ProseMirror source-map and outdated Browserslist warnings remain.

Current hosted Ruby audit: `bundle exec bundle-audit check --update` **PASS**, no vulnerabilities found. JavaScript audits remain **FAIL**: production graph 0 critical / 23 high / 17 moderate / 5 low; complete graph 2 critical / 54 high / 37 moderate / 8 low. These are advisory findings, not unique exploitable package counts.

Additional local focused runs passed 9 files / 147 tests, then 4 files / 11 tests after the paired Vite plugin update. The hosted unseeded production-critical batch passed 200 examples, runtime configuration 5 examples, and n8n API 3 examples. The first 200-example run had one new Instagram logging fixture failure; registering the provider error before a validation-triggered token refresh fixed setup ordering without weakening the assertion.

Source and result links:

- Starting candidate CI: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38136049044 (historical to this execution: 6,022 examples / 73 failures / 2 pending; all failures reproduced on base comparisons).
- Initial security-change full CI: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38139086522.
- Initial non-publishing candidate build: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38139086426.
- Fresh base comparison: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38139478412 at `452f849bc5d2c45b682dcc1e1e4d44ca43c102a9`.
- Passing migration/security/focused verification: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38141876926.
- Final source full CI: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38141876845.
- Final source candidate build: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38141876893.

The initial security-change full run completed 6,024 examples / 77 failures / 2 pending. All 77 failed example identities occur in actual base-run artifacts: the fresh base run completed 5,997 examples / 62 failures / 2 pending, and the earlier base full run adds order/environment-dependent failures. This establishes baseline reproduction, not release acceptance. The corresponding frontend run completed 3,802 passed / 20 failed tests. Final-source totals remain pending until every shard completes. Superseded runs were canceled rather than treated as passing.

The earlier image at `d84b5cf818b3aeb9e1d849ac2b7445bed5885bf6` built with manifest digest `sha256:cdb29bd5efc5860eff3c3796b80c9f2f83c4d2ad9626d6f978d7b8c67755a460`; it is not the final candidate. Its isolated migration, DB/Redis and Sidekiq checks passed, but restart readiness returned curl exit 7 after a fixed 15-second delay. The smoke script now polls readiness with a bounded timeout; successful final execution is still required. No image was published.

Do not equate an in-progress run or one successful shard with a passed suite. Detailed final outcomes are recorded after completion.

## Application and deployment audit boundaries

Existing WhatsApp signature verification requires Cloud/unknown channels to be signed; missing/invalid secrets cannot bypass it. Routing, encrypted channel configuration, existing provider HTTP timeouts, tenant-scoped APIs, duplicate message indexes, deletion scoping and n8n ownership/idempotent delivery contracts were inspected. Existing request/spec coverage must pass in current CI before release. No inbound contract, widget behavior or onboarding portal was changed.

Production Compose uses the required image variable, a one-shot migration service and web/Sidekiq dependents. n8n Compose defines separate PostgreSQL/Valkey/main/worker, shared encryption and queue variables, persistent volumes and authenticated readiness. The example specifies queue mode; rendered values must also be checked. Only main receives a public route. Inbox database/Valkey remain separate private Coolify resources on the same VPS.

Migration commands: first setup/upgrade uses `RAILS_ENV=production bundle exec rails db:chatwoot_prepare`; explicit upgrade is `RAILS_ENV=production bundle exec rails db:migrate`. Retain verified backups and keys before migration/backfill. Quick Menu rollback drops saved menus. The n8n repair migration is intentionally irreversible; use an application rollback that preserves compatible schema or an explicitly planned restore/forward fix. Current disposable PostgreSQL 16 fresh/upgrade/schema-dump and Quick Menu reversal checks passed. HairTrigger schema dumping is fixed. No production database was touched.

## External acceptance still required

An authorized non-production account, test phone, legitimate signed Meta webhook ingress, protected Inbox AgentBot/HMAC credentials and a queue-mode n8n workflow are needed. The operator must initiate the test inbound message. Verify buttons (1–3 items), list (4–10), each inbound visible title, n8n reply, normal text, duplicate replay, closed window, cross-account rejection and human takeover. No real customer may be used.

Before purchasing: candidate build/boot, security disposition and production-critical tests must pass. After the actual server exists: Coolify networking/TLS, storage/SMTP, reboot recovery, encrypted off-server backup and isolated restore, alert delivery, load/headroom and first-client acceptance must be measured. Local disposable testing is not KVM validation and the single-VPS topology does not provide zero-downtime failover.
