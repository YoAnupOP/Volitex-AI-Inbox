# Production candidate verification — 2026-10-11

**Authorized publication completed:** see [2026-10-19 pullable artifact and verification](application-publication-2026-10-19.md). This supersedes earlier statements that source66 has no published artifact; KVM acceptance and traffic authorization remain outstanding.

**Latest reconciliation:** [2026-10-19 exact-source results](antigravity-reconciliation-2026-10-19.md) supersede historical candidate results below; publication and actual KVM acceptance remain separate.

**Current integrated candidate:** see [2026-10-17 candidate evidence](integrated-release-candidate-2026-10-17.md) for the exact campaign + maintenance source, current CI results, publication boundary and remaining KVM/client acceptance gates. Historical artifacts below must not be substituted for this candidate.

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
- FAIL: latest completed full CI has 34 backend and 19 frontend baseline-reproduced failures. Final patched candidate image/boot/scan remain blocked; an older comparison image passed boot/restart but was rejected by its security inventory.
- BLOCKED: authorized Docker/WSL maintenance was performed after the later outage. WSL recovered, but Docker Desktop fails to rename its sailor-ingest socket and has no engine connection. Existing local Docker services have not yet been confirmed restored.
- BLOCKED externally: no explicitly identified authorized test number/account and non-production Meta/n8n environment.
- NOT RUN: production deployment, image publication, live migrations, KVM reboot, backup restore and monitoring alert drills.

## Environment evidence

Host Node `22.14.0`, pnpm `10.2.0`; repository requires Node 24 and hosted CI uses 24. Host Ruby/Bundler are absent. Docker client `29.8.0`, Compose `5.5.1`, WSL `2.6.1.0`, kernel `6.6.87.2-1`. Docker server version probe timed out after 20 seconds; Ubuntu Ruby probe also timed out after 20 seconds. Windows had approximately 180 GB free disk and 8.7 GB free physical memory during diagnostics. These observations do not establish an OOM or disk-exhaustion cause.

Safe recovery requires a maintenance window for local development services: stop their active work, quit Docker Desktop, run `wsl --shutdown`, reopen Docker Desktop, and verify `docker version`/container health. This interrupts every WSL distribution and Docker workload; it was subsequently performed with explicit operator authorization. Do not prune volumes, factory-reset Docker or delete WSL distributions. Hosted non-production CI avoids requiring extra infrastructure.

At 19:08 IST, Docker and Ubuntu WSL recovered without a restart. Docker client/server 29.8.0 and Ubuntu Python/Docker execution responded. Existing Inbox/n8n services remained running. The private local n8n probe passed using the pinned images, disposable credentials, separate project/volumes and no published ports; worker absence caused the expected webhook timeout, and starting the worker produced the expected response and successful execution. This is queue/component integration evidence, not the production HMAC workflow or full Inbox API round trip.

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
- Reply creation and Quick Menu sending now hold the conversation row lock while checking current ownership and creating the message. This uses the same lock as handoff, preventing stale loaded ownership from authorizing a new reply after takeover. Both new stale-conversation regressions passed at `d2dd1bfbd19c919d726acef3d33c1c6b0159230e`: 201 production-critical / 5 guard / 4 n8n API examples, zero failures. Already accepted/in-flight provider deliveries are not canceled by this change.
- Moved the Docker revision argument immediately before its stamp; no earlier source reads it. Changing Git SHA no longer invalidates native dependency installation. The earlier hosted bundle installation took 2,118 seconds, including native gRPC compilation; this was a completed slow build, not evidence of an unresponsive CI daemon.
- Updated Ruby 3.4.4 to 3.4.11 and the image base from Alpine 3.21 to 3.23. A real base-image probe loaded zlib 3.2.1, affected by [CVE-2026-27820](https://www.ruby-lang.org/en/news/2026/03/05/buffer-overflow-zlib-cve-2026-27820/); the replacement loads fixed zlib 3.2.3. `bundle lock` under Ruby 3.4.11 regenerated only Ruby metadata, preserving every resolved gem version. The candidate smoke gate now rejects zlib below 3.2.3. Alpine 3.21 [support ends on 2026-11-01](https://alpinelinux.org/releases/). Full application regression/build verification of the replacement is pending.
- Added asset compilation before rendered-view RSpec examples after inspecting actual `ViteRuby::MissingEntrypointError` failures. The first CI attempt exhausted Node's default heap; the corrected step explicitly uses the same 4 GB heap allowance as the production Docker build. No expectations or tests were removed.
- Fixed duplicate ActionCable teardown during reconnect: clear references before unsubscribing/disconnecting, so replacement and repeated shutdown cannot unsubscribe the old connection twice. Five existing connector regressions pass, including an added repeated-teardown call. Formatting and focused ESLint pass; a single stateless diagnostic-method exception follows the surrounding class convention and excludes instance credentials. No blanket lint rules were disabled.
- A real Trivy image scan discovered committed dependency test fixtures under `/gems/.../devise-secure_password/.../node_modules`, despite `/app/node_modules` being absent. Production packaging now removes those unused directories before copying gems into the final image, excludes app test directories, and never copies npm/corepack packages into production layers. Development image tooling remains available. The strengthened smoke gate checks these locations. Actual post-fix image scanning is pending.
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

The [remaining high/critical advisory inventory](production-candidate-advisories.csv) records exact installed versions, advisory IDs, fixed-version ranges and dependency paths. Build-only reachability is distinguished from browser/runtime exposure; artifact inventory and an explicit release disposition remain required. Gitleaks scanned the nine new committed changes through `46708d08c1` with redaction enabled and found no leaks; this is not a whole-history credential audit.

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
- Passing atomic ownership/migration verification: https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38143374380.

The initial security-change full run completed 6,024 examples / 77 failures / 2 pending. All 77 failed example identities occur in actual base-run artifacts: the fresh base run completed 5,997 examples / 62 failures / 2 pending, and the earlier base full run adds order/environment-dependent failures. This establishes baseline reproduction, not release acceptance. At `56c45ab`, the full RSpec run completed **6,032 examples / 76 failures / 2 pending**, with zero failed identities absent from those base artifacts. The full frontend run completed **3,803 passed / 20 failed tests**; all 20 failure headings match the fresh base exactly after ANSI normalization. Failed files concern theme/appearance helpers and ActionCable. Superseded runs were canceled rather than treated as passing. Verification of the later atomic-ownership fix is tracked separately.

Normal repository-wide RuboCop inspected 2,104 files and reported 2,099 offenses after the new migration/Instagram formatting fixes; inherited CRLF remains on existing changed Ruby files. ESLint reported 260,070 problems (259,654 errors / 416 warnings). No blanket rule disable was added. The new clipboard spec passed its focused ESLint check. No separate application type-check script was found. `git diff --check`, shell syntax and three mocked entrypoint checks passed.

The earlier image at `d84b5cf818b3aeb9e1d849ac2b7445bed5885bf6` built with manifest digest `sha256:cdb29bd5efc5860eff3c3796b80c9f2f83c4d2ad9626d6f978d7b8c67755a460`; it is not the final candidate. Its isolated migration, DB/Redis and Sidekiq checks passed, but restart readiness returned curl exit 7 after a fixed 15-second delay. The smoke script now polls readiness with a bounded timeout; successful final execution is still required. No image was published.

Do not equate an in-progress run or one successful shard with a passed suite. Detailed final outcomes are recorded after completion.

### Later verification evidence

At `d2dd1bfbd19c919d726acef3d33c1c6b0159230e`, [full backend CI](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38143373094) completed **6,034 examples / 69 failures / 2 pending**. Every failed example identity occurs in the actual base artifacts. The [identity comparison CSV](production-candidate-baseline-failures.csv) records each example and the reproducing base run. This is baseline reproduction, not clearance of those behaviors for launch. Portal/superadmin view failures include missing compiled Vite entrypoints; CSAT provider expectations and other baseline failures still require assessment after the asset setup fix.

The original seven selected failures are individually recorded in [Quick Menu verification](quick-menu-verification.md). Three Facebook/Instagram window assertions reproduced on seeded base because persisted GlobalConfig overrides the test environment; four inbound-contact assertions reproduced because seed contact Jane occupied `Contact.all.first`. The unseeded base batch passed 49 examples. Current unseeded feature verification passed 201 production-critical examples plus five configuration and four n8n API examples at [run 38143374380](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38143374380), including the new stale-ownership regressions.

The local pre-runtime-update build at `8dcf30b738c57a65794962873ae8e8423cc1afc5` completed production asset compilation. Exported local manifest list: `sha256:c416b0dc3c95de3eadd64b5d2346c65c66cfb6726c05f7985afb055fcb829c26`; config: `sha256:fe532772b49ccdce98d0f11017b7b9d18c0df305f4902d637b332af2f68a20a6`. This is an unpublished comparison image containing old zlib, not an approved release artifact. The exact patched candidate at `bab8c88db011010349b635ae88dd2aeb862aedbf` is being built locally and in [non-publishing CI](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38146648152). Its [full CI](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38146648138) and [migration/focused verification](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38146672011) are pending; they are not reported as passes.

Subsequent results: the local comparison image passed disposable preparation, web/Sidekiq boot, DB/Redis connectivity, restart and stop. The same revision's [hosted candidate gate](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38144383716) also passed. It remains rejected for release because the image scan found vulnerable runtime/default packages and unused fixture/tool dependencies.

At `bab8c88db0`, migration/focused run **38146672011 passed all 210 examples**, the Ruby audit, fresh migrations/schema dumping, prior-schema upgrade, constraints and Quick Menu down/up verification. All 16 full-CI asset compilation steps passed with the corrected heap setting. The backend results were **6,034 examples / 34 failures / 2 pending**, with zero unmatched baseline identities. Remaining failures include Instagram comments/OAuth, WhatsApp CSAT, account/mailers, Hub/CRM and third-party integrations; reproduction on base does not resolve their launch impact. The frontend and normal repository lint/security gates remain separately reported.

Trivy 0.75.0 scanned the actual comparison image: Alpine **0 critical / 6 high**, Node package inventory **33 critical / 203 high**, Ruby/default gems **2 critical / 7 high**. Most Node findings are dependency fixture installations; eight high findings are unused global npm packages, and one identifies an uninstalled Playwright test-project manifest. Ruby 3.4.11's directly probed default versions are zlib 3.2.3, net-imap 0.5.15, resolv 0.7.2, uri 1.0.4 and erb 4.0.4.1, meeting the scan's respective fixed ranges. Application Bundler versions net-imap 0.6.7, uri 1.1.1 and erb 6.0.7 were already patched; the old base defaults were still packaged. No scan finding was suppressed.

The final code candidate `2fdcb93a11385cc0c010d0595af64523a58f6c4d` is built from `git archive` input, excluding uncommitted reports and untracked files. Local command: `git archive --format=tar --output=<temporary-source.tar> <sha>`, then `docker build --file docker/Dockerfile --build-arg GIT_SHA=<sha> --tag volitex-candidate-exact:<sha> - < <temporary-source.tar>`. This build, the strengthened isolated smoke gate and post-fix image scan are pending. Superseded builds were canceled; cancellation is not a pass.

## Application and deployment audit boundaries

Existing WhatsApp signature verification requires Cloud/unknown channels to be signed; missing/invalid secrets cannot bypass it. Routing, encrypted channel configuration, existing provider HTTP timeouts, tenant-scoped APIs, duplicate message indexes, deletion scoping and n8n ownership/idempotent delivery contracts were inspected. Existing request/spec coverage must pass in current CI before release. No inbound contract, widget behavior or onboarding portal was changed.

Production Compose uses the required image variable, a one-shot migration service and web/Sidekiq dependents. n8n Compose defines separate PostgreSQL/Valkey/main/worker, shared encryption and queue variables, persistent volumes and authenticated readiness. The example specifies queue mode; rendered values must also be checked. Only main receives a public route. Inbox database/Valkey remain separate private Coolify resources on the same VPS.

Migration commands: first setup/upgrade uses `RAILS_ENV=production bundle exec rails db:chatwoot_prepare`; explicit upgrade is `RAILS_ENV=production bundle exec rails db:migrate`. Retain verified backups and keys before migration/backfill. Quick Menu rollback drops saved menus. The n8n repair migration is intentionally irreversible; use an application rollback that preserves compatible schema or an explicitly planned restore/forward fix. Current disposable PostgreSQL 16 fresh/upgrade/schema-dump and Quick Menu reversal checks passed. HairTrigger schema dumping is fixed. No production database was touched.

## External acceptance still required

An authorized non-production account, test phone, legitimate signed Meta webhook ingress, protected Inbox AgentBot/HMAC credentials and a queue-mode n8n workflow are needed. The operator must initiate the test inbound message. Verify buttons (1–3 items), list (4–10), each inbound visible title, n8n reply, normal text, duplicate replay, closed window, cross-account rejection and human takeover. No real customer may be used.

The operator clarified that `inbox.volitexai.tech` is the unchanged Heroku App Review deployment and the old token is compromised. No callback or connected inbox was changed, and no token was reused. Graph DNS/TLS connectivity passed with an unauthenticated HTTP 400 response; authenticated prerequisites remain blocked. The [isolated live-test proposal](isolated-whatsapp-verification.md) requires a separate app/test resources, protected replacement token and explicit approval before either direct or full-flow live sends.

Before purchasing: candidate build/boot, security disposition and production-critical tests must pass. After the actual server exists: Coolify networking/TLS, storage/SMTP, reboot recovery, encrypted off-server backup and isolated restore, alert delivery, load/headroom and first-client acceptance must be measured. Local disposable testing is not KVM validation and the single-VPS topology does not provide zero-downtime failover.

### Latest source and environment verification

Source HEAD before this report commit: `bf28d521993df8ac3810b2615f58ac1c14719644`. Existing feature history is preserved, and fixes were pushed without force. The primary dirty checkout is untouched.

- Completed full CI [38147539800](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38147539800): **6,034 backend examples / 34 failures / 2 pending**, with zero failed descriptions absent from the recorded baseline; **3,804 frontend passes / 19 failures**, all 19 normalized failure headings present in the base's 20. ActionCable's previous failure is resolved. This suite remains red.
- Latest focused hosted run [38148212436](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38148212436): **BLOCKED**, not a test failure. GitHub reports that jobs were not started because recent account payments failed or the spending limit needs increasing. No billing configuration was changed.
- Latest local focused frontend: **10 files / 152 tests PASS**, plus widget **4 files / 6 tests PASS**. Changed Ruby lint: **15 Ruby files PASS**; this does not establish repository-wide lint cleanliness or include the subsequently changed Gemfile.
- Patched-image hosted build [38147539816](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38147539816): **FAIL**, Scout APM 5.3.3 native extension callback is incompatible with GCC 15. Its documented compatible fix was resolved to Scout 5.7.1 with Bundler 2.5.16, preserving other gem versions. Native GCC 15 compilation and the actual `ScoutApm::Instruments::Allocations.count` C-extension call **PASS**. Final image build/boot remain unverified.
- gRPC's native build now uses `GRPC_RUBY_BUILD_PROCS=2` rather than automatically using all advertised CPUs. This limits build resource demand; it is not proof that the earlier WSL failure was an OOM.
- Candidate CI now includes a pinned Trivy 0.75.0 HIGH/CRITICAL runtime scan that fails on findings and retains the JSON report, without exclusions or `--ignore-unfixed`. The new gate has not executed because hosted access is blocked.
- The operator requested Docker recovery last after reporting the exact `sailor-ingest.sock` rename failure. WSL service recovery and the Docker privileged helper startup succeeded; the engine remains unavailable. No factory reset, volume prune, distribution deletion or production change was performed.
- Independent verification uses Ubuntu 26.04, isolated rbenv Ruby 3.4.11/Bundler 2.5.16, and a disposable PostgreSQL 18 instance listening only on its own Unix socket with a private Redis port. The existing PostgreSQL 18 main cluster remains untouched. Native checks are additional evidence, not a substitute for the already completed PostgreSQL 16 migration checks or the final production-image gate.

Commands and result logs are retained locally under the operator's temporary directory (`volitex-final-packaging-full-ci.log`, `volitex-final-packaging-full-rspec`, `volitex-native-final-bundle.log`, `volitex-scout-native-smoke.log`). They contain synthetic test data, not production credentials. A source-only audit cannot establish the vulnerability inventory of an unbuilt final image.

### Baseline failure assessment

The final 34 backend failures are individually reproducible on the supplied base, but are not uniformly approved release exceptions:

- WhatsApp CSAT (three): exact HTTParty expectations omit the existing `open_timeout: 5` / `timeout: 15` options. Preserve bounded production timeouts. This evidence points to stale mocks, not a demonstrated provider failure; actual template delivery remains unverified.
- Instagram OAuth/comments (five): callback stub omits the subscribed `comments` field, and CommentsClient stubs omit actual token/fields/limit query parameters. An additional comments-service assertion remains a separate unresolved behavior. No real provider requests were permitted by WebMock. Live Instagram integration remains a release acceptance requirement.
- AgentBot assignment/status/priority (three): legacy success expectations provide no required inbox mapping/control-plane authorization and receive HTTP 401. Preserve account/inbox authorization; current focused n8n ownership tests exercise the supported path.
- Schedule (one): the line-based duplicate detector counts CRLF blank lines as keys; the actual YAML defines ten distinct jobs. This is a fixture/platform issue, not evidence that Sidekiq schedules contain duplicate keys. No assertion was weakened.
- Remaining Hub/CRM/Linear, mailers, portal/superadmin and user failures still require individual launch-path assessment. Baseline status alone is insufficient for release acceptance.
- All 19 frontend failures concern portal theme, dashboard theme and disabled appearance hotkeys. The base produces the same failed headings. Portal light-only behavior and disabled hotkeys were not changed to satisfy obsolete expectations; dashboard theme mocks remain unresolved.

The repository-wide suites and lint remain red. No test was skipped, assertion weakened, authentication bypassed or unrelated dependency broadly upgraded to hide these results.

Docker recovery evidence: after docker desktop stop --force --timeout 30 succeeded, both zero-length ingest endpoints remained reparse points (attributes 1056). Preservation with PowerShell Move-Item failed with the same system access error. Automatic approval review rejected targeted endpoint removal; no removal executed and no bypass was attempted. Operator screenshot corroborates the exact startup error. Quit Docker Desktop and reboot Windows, then check engine and existing service health; if the error persists, use Docker support diagnostics before any data reset. This recovery remains before-purchase work.

### Final independent check results

The frozen `bf28d521993df8ac3810b2615f58ac1c14719644` Git archive completed native bundle installation (154 Gemfile dependencies / 361 gems), including gRPC with two compiler workers and Scout 5.7.1. In isolated Ubuntu 26.04 / Ruby 3.4.11 / PostgreSQL 18 / Redis, the latest code passed **201 production-critical + 5 runtime-guard + 4 n8n API examples, zero failures**. This includes the concrete-controller regression stub and current agent attribution/ownership behavior. `bundle exec bundle-audit check --update` passed against advisory DB commit `a6847b0651a702488f5844081e848dd1ec9dbf1d` (1,263 advisories). Schema loading into a fresh disposable database passed; PostgreSQL 16 fresh migrations/upgrade/reversal evidence is recorded above.

Executed commands (rbenv initialized first; frozen Bundler 2.5.16, separate gem path, test encryption keys and private DB/Redis endpoints):

```sh
bundle _2.5.16_ install --jobs 2 --retry 2
bundle _2.5.16_ exec rails db:create db:schema:load
bundle _2.5.16_ exec rspec <the 17 production-critical spec paths in verify_migration_compatibility.yml> --format progress --format json --out tmp/native_production_critical_results.json
bundle _2.5.16_ exec rspec spec/lib/volitex_production_configuration_spec.rb --format progress --format json --out tmp/native_runtime_guard_results.json
bundle _2.5.16_ exec rspec spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb --example 'Volitex n8n AgentBot' --format progress --format json --out tmp/native_n8n_api_results.json
bundle _2.5.16_ exec bundle-audit check --update
bundle _2.5.16_ exec rubocop --force-exclusion Gemfile <15 changed Ruby files>
```

The exact executable command list is retained in `volitex-native-final-tests.sh` / `volitex-native-final-lint.sh`; result logs/JSON are `volitex-native-final-tests.log`, `volitex-native-final-results`, and `volitex-native-final-lint-corrected.log` in the operator's temporary directory. Native Node 22.22.1 provides ExecJS for these backend checks; it is not the Node 24 production image environment. No frontend build was claimed from this native run.

Initial explicit lint accidentally included `db/schema.rb` despite its existing repository exclusion (2,010 generated-schema offenses) and found Gemfile's CRLF offense. Corrected lint respects the existing exclusions with `--force-exclusion`; only the already changed Gemfile was normalized to LF. **16 files inspected, no offenses detected**. No cop was disabled and generated schema was not reformatted. `git diff --ignore-space-at-eol -- Gemfile` is empty for this normalization.

Gitleaks scanned all 20 new commits through `bf28d52199` with redaction: **no leaks found**. Formatting and `git diff --check` passed. The disposable PostgreSQL and Redis processes were stopped; the pre-existing PostgreSQL 18 main cluster remains online. Docker workloads remain unconfirmed because Desktop has no engine connection. Final candidate image build/boot/Trivy, n8n image audit, authenticated Meta prerequisites, and live delivery remain blocked/not run; none is inferred from these native passes.
