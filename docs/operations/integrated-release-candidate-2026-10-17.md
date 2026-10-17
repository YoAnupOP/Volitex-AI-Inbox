# Integrated release candidate — 2026-10-17


## Release decision

**GO for explicitly authorized candidate image publication. NO-GO for client traffic until actual KVM acceptance.** The integrated application, migrations, campaign failure/recovery/load gates, and exact-image build/boot/scan passed. Full CE remains red on the precisely identified inherited failures and lint/build-tool debt below; it is not described as green. No production publication, deployment, callback change, campaign enablement or live send occurred.

## Source and scope

Candidate source: `45601e7ba53cfce240c7a26fe77bfa518ff8a7e5`, branch `codex/integrated-release-candidate-20261017`.

Maintenance was already a descendant of campaign source `17dbb0898dad02ced7c3db6060c961617dd6354d`. Maintenance source `cc1c06d0c76108c710edbd0da39049c991402dde` and reported HEAD `216ce98cc094bfb346dc9fd7767750ea339ded8c` differ only by maintenance documentation. No merge of unrelated upstream/develop history was attempted. Original branches/worktrees and the primary checkout's unrelated changes were preserved.

The candidate adds two narrow runtime repairs (Super Admin Rails migration API and Instagram comment lock reload), faithful HTTP/auth/theme test fixtures, integrated verification triggers, restored-campaign-schema/worker-heartbeat checks, and an explicit manual publication workflow that builds, boots and scans before any authorized push. No campaign gate, ownership, consent, encryption, webhook authentication or tenant policy was weakened. No dependency, migration or n8n image change.

## CE #70 / #71 investigation

Inspected complete logs, job/step metadata, annotations and all 16 JSON test artifacts for [#70](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39021865032) (`17dbb089...`) and [#71](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39024066329) (`cc1c06d...`), against predecessor [#67](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39004343513) (`fa6fa33b35b86c0908b4aa1fcf955925b2ace4e4`). Workflow: `.github/workflows/run_foss_spec.yml`, Ubuntu hosted runners, Ruby 3.4.11 / Node 24 / PostgreSQL pgvector16 / Redis, 16 backend shards. Dependency installation, schema and assets succeeded; tests, repository lint and JS dependency audit failed. Annotations corroborate test/lint nonzero exits, with action Node deprecation/cache warnings; no failed-run infrastructure/billing denial.

Backend: predecessor 6,042 examples / 34 failures; #70 6,076 / 34; #71 6,088 / 34. Compared exception classes and messages, not names alone. 28 messages are byte-identical across all three. Remaining differences are generated fixture IDs/timestamps, OTP fixture values, rendered invitation names/URLs and schedule counts. Rails logs establish the shared runtime/mocking causes. Source blobs for both runtime defects and the Instagram client are unchanged between predecessor and #71. Schedule count changed from 20 parsed / 11 unique to 22 / 12 because the CRLF parser counted blank lines and an additional real schedule entry; this was not an exact-error match or a real duplicate schedule.

No production or generated fixture credentials are reproduced here. Full raw artifacts remain attached to the CI runs.

| Failed example (complete identity) | Cause and disposition |
|---|---|
| Super Admin Instance status GET /super_admin/instance_status when it is an authenticated super admin shows the instance_status page | Runtime defect: obsolete connection.migration_context API; controller and rendered response fixed. |
| with valid schedule.yml does not have duplicates | Harness: CRLF blank lines counted as keys; Psych syntax-tree duplicate detection preserves assertions. Counts differ as schedule grew. |
| Linear Integration API POST /api/v1/accounts/:account_id/integrations/linear/create_issue when it is an authenticated user when the issue is created successfully returns the created issue | Harness: mock expected Hash, controller correctly passes permitted Parameters; exact argument type corrected. |
| Linear Integration API POST /api/v1/accounts/:account_id/integrations/linear/create_issue when it is an authenticated user when the issue is created successfully creates activity message when conversation is provided | Harness: mock expected Hash, controller correctly passes permitted Parameters; exact argument type corrected. |
| Linear Integration API POST /api/v1/accounts/:account_id/integrations/linear/create_issue when it is an authenticated user when issue creation fails returns error message and does not create activity message | Harness: mock expected Hash, controller correctly passes permitted Parameters; exact argument type corrected. |
| Api::V1::Accounts::BaseController when agent bot belongs to the account allows assignments via API | Harness: positive bot fixture lacked required inbox mapping; mapping added, unmapped negative assertion added. |
| AdministratorNotifications::AccountNotificationMailer#account_deletion_user_initiated sets the correct subject for user-initiated deletion | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| AdministratorNotifications::AccountNotificationMailer#account_deletion_for_inactivity sets the correct subject for system-initiated deletion | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| User 2FA/MFA functionality #two_factor_provisioning_uri generates a valid provisioning URI for QR code | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| Devise::Mailer notify has the correct header data | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| Devise::Mailer notify shows the default confirmation state | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| Devise::Mailer notify when there is an inviter refers to the inviter and their account | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| ChatwootHub.base_url uses the static hub url | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| ChatwootHub when fetching sync_with_hub get latest version from chatwoot hub | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| ChatwootHub when fetching sync_with_hub will not send instance metrics when telemetry is disabled | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| ChatwootHub when fetching sync_with_hub returns nil when chatwoot hub is down | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| ChatwootHub when register instance sends info of registration | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| ChatwootHub when sending events will send instance events | Retained baseline: fork intentionally disables upstream hub registration/telemetry and uses Volitex hub URL; obsolete upstream expectations. |
| Whatsapp::CsatTemplateService#create_template creates template with generated name | Harness: exact HTTP mock omitted required open_timeout=5/timeout=15; bounded timeouts retained. |
| Whatsapp::CsatTemplateService#delete_template makes DELETE request to correct endpoint | Harness: exact HTTP mock omitted required open_timeout=5/timeout=15; bounded timeouts retained. |
| Whatsapp::CsatTemplateService#get_template_status makes GET request to correct endpoint | Harness: exact HTTP mock omitted required open_timeout=5/timeout=15; bounded timeouts retained. |
| Conversations API POST /api/v1/accounts/{account.id}/conversations/:id/toggle_status when it is an authenticated bot returns authorized for arbritrary status | Harness: bot was mapped to another inbox; positive fixture now maps to target conversation inbox; authorization unchanged. |
| Conversations API POST /api/v1/accounts/{account.id}/conversations/:id/toggle_priority when it is an authenticated bot toggle the priority of the bot agent conversation | Harness: bot was mapped to another inbox; positive fixture now maps to target conversation inbox; authorization unchanged. |
| Instagram::CallbacksController#show when authorization is successful creates instagram channel and inbox | Harness: subscribed-fields HTTP stub omitted comments; all four fields explicitly asserted. |
| Public::Api::V1::PortalsController GET /public/api/v1/portals/{portal_slug} Throws unauthorised error for unknown domain | Retained baseline: literal Chatwoot identity/address expected while intended fork renders Volitex identity/address; not an authorization or transport error. |
| Crm::Leadsquared::SetupService#setup when fetching activity types succeeds when all required types exist uses existing activity types and updates hook settings | Retained baseline: expected activity labels contain Chatwoot, implementation uses Volitex; optional CRM path. |
| Crm::Leadsquared::SetupService#setup when fetching activity types succeeds when some activity types need to be created creates missing types and updates hook settings | Retained baseline: expected activity labels contain Chatwoot, implementation uses Volitex; optional CRM path. |
| Crm::Leadsquared::SetupService#activity_types defines conversation started activity type | Retained baseline: expected activity labels contain Chatwoot, implementation uses Volitex; optional CRM path. |
| Crm::Leadsquared::SetupService#activity_types defines transcript activity type | Retained baseline: expected activity labels contain Chatwoot, implementation uses Volitex; optional CRM path. |
| ReplyMailbox when a chatwoot notification email is received shouldnt create a conversation in the channel | Retained baseline: legacy notification-email fixture uses Chatwoot sender; fork notification sender is Volitex. Not changed; email channel outside initial WhatsApp/Instagram scope. |
| Instagram::CommentsClient preserves Meta usernames and uses the connected inbox identity only for self-authored records without one | Harness: HTTP query absent from stub; request query asserted. Two fixtures serialized response before per-example mutations; lazy response body now exercises intended tree/identity assertions. |
| Instagram::CommentsClient keeps a reply nested when Meta also includes the same ID as a top-level comment | Harness: HTTP query absent from stub; request query asserted. Two fixtures serialized response before per-example mutations; lazy response body now exercises intended tree/identity assertions. |
| Instagram::CommentsClient uses parent IDs to preserve separate reply branches at every depth | Harness: HTTP query absent from stub; request query asserted. Two fixtures serialized response before per-example mutations; lazy response body now exercises intended tree/identity assertions. |
| Instagram::CommentsService creates one inbound message for repeated delivery of the same customer comment ID | Runtime defect: DB-trigger-assigned display_id left new Conversation dirty before with_lock; reload before locking. Existing replay test strengthened. |

16 prior failures are addressed; 18 unrelated branding/disabled-hub/legacy-fixture failures are deliberately retained. Final candidate confirms these 16 failures are absent, with no new failed identities. Of the 18 retained errors, 15 messages are byte-identical to #71; three differ only in generated OTP identity/secret or rendered invitation/confirmation fixture values. The security assertions are unchanged.

Frontend #70/#71: same 19 failures. Six dashboard-theme tests passed obsolete positional arguments instead of stubbing matchMedia; corrected without changing product theme behavior. Other 13 concern the intentionally light-only portal and removed appearance hotkeys; product behavior is unchanged and they remain baseline debt. No test is skipped or assertion removed to make CI green.

## Verification

Earlier green campaign and maintenance runs are predecessor evidence only. The following runs use the exact candidate source above.

| Check | Actual result on candidate |
|---|---|
| [Full CE #73](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39027443210) | FAIL overall; 6,089 backend examples: 6,069 passed, 18 failed, 2 pending. Frontend 397 files: 395 passed, 2 failed; 3,846 tests passed, 13 failed. No new failure identities. All 13 retained frontend exception/expected/received signatures match #71. |
| [Migration compatibility](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39027443176) | PASS: empty database migrations/schema dump; campaign and Quick Menu down/up; upgrade from schema at 452f849bc5d2c45b682dcc1e1e4d44ca43c102a9; campaign tables and Quick Menu FK/index/check constraints; unseeded production-critical specs 203/0, runtime guards 5/0, tenant-bound n8n API 4/0. |
| Repository lint | FAIL inherited: RuboCop 2,125 files / 2,110 offenses (4 fewer than #70/#71); ESLint 258,472 errors / 420 warnings (76 fewer errors than #71). Not called green or entirely predecessor-identical; campaign-added metric offenses are inherited from #70, not newly introduced by integration. |
| Dependency audit | Ruby bundle-audit PASS, no advisories. pnpm audit --prod --audit-level high FAIL: unchanged 16 findings, 1 high / 10 moderate / 5 low. |

Local focused checks:

- `bundle exec rspec spec/controllers/super_admin/instance_statuses_controller_spec.rb spec/configs/schedule_spec.rb spec/controllers/api/v1/accounts/integrations/linear_controller_spec.rb spec/requests/api/v1/accounts/base_controller_spec.rb spec/controllers/api/v1/accounts/conversations_controller_spec.rb spec/controllers/instagram/callbacks_controller_spec.rb spec/services/instagram/comments_client_spec.rb spec/services/instagram/comments_service_spec.rb spec/services/whatsapp/csat_template_service_spec.rb`: **150 examples, 0 failures**. First rerun uncovered two response fixtures serialized before mutation; corrected with lazy WebMock bodies. A subsequent local run had one dispatcher-spy reinitialization failure; unchanged rerun passed and the final full CI test passes. No product workaround or weakened assertion was added for that transient.
- `pnpm exec vitest run app/javascript/dashboard/helper/specs/themeHelper.spec.js`: **10/10 passed**.
- `pnpm exec vitest run app/javascript/dashboard/helper/specs/themeHelper.spec.js app/javascript/dashboard/helper/specs/adminAuth.spec.js app/javascript/dashboard/helper/specs/MessageFormatter.spec.js app/javascript/dashboard/components-next/message --maxWorkers=2 --minWorkers=2 --reporter=dot`: **5 files / 42 tests passed**.
- `pnpm exec vitest run app/javascript/dashboard/components-next/quickMenus/specs app/javascript/dashboard/routes/dashboard/settings/quickMenus/specs app/javascript/dashboard/components-next/Campaigns/specs app/javascript/dashboard/store/modules/specs/campaigns app/javascript/dashboard/api/specs/campaign.spec.js app/javascript/dashboard/components-next/message/bubbles/specs app/javascript/dashboard/helper/specs/MessageFormatter.spec.js app/javascript/dashboard/routes/dashboard/auth/specs app/javascript/dashboard/components-next/conversation/specs --maxWorkers=2 --minWorkers=2 --reporter=dot`: **11 files / 45 tests passed**. Nonmatching filters add no tests; passing file counts are the actual discovered files, not a claim every filter exists.
- `node --test script/production/specs/n8n_reply.test.cjs script/production/specs/vue_ssr_security.test.cjs`: **10 tests passed**.
- `node --test script/production/specs/n8n_compression_ingress.test.cjs`: **1 passed**, exact official n8n/Traefik digests; positive gzip control allocated one compressor, guarded routes allocated zero across 7 encodings, 4 route classes, 6 bounded disconnects and restart; auth 401, missing webhook 404, no direct backend host port. No live message or disruptive exhaustion test.
- `pnpm exec eslint app/javascript/dashboard/helper/specs/themeHelper.spec.js` and `pnpm exec prettier --check app/javascript/dashboard/helper/specs/themeHelper.spec.js`: **PASS**.
- Changed Ruby RuboCop: **FAIL only 9 inherited Layout/EndOfLine offenses**, no remaining new line-length/indentation offense. Existing mixed/CRLF source bytes preserved outside edited lines; no lint suppression added. Full lint results above remain red.
- Ruby YAML parse of all workflows, `bash -n script/production/verify_candidate.sh`, `git diff --check`: **PASS**. No applicable TypeScript source changed or separate repository typecheck script found.

The first integration commit b6c799ea0e1d9bd920c907f2af487ac12f8461e0 had a new rendered-request CI setup failure in the added campaign/maintenance job (240 examples / one Super Admin HTTP500 without built test assets). Commit 45601e7 adds same-source asset compilation; the final maintenance batch passes all 240 examples. This is separate from the old migration_context defect and is not described as a baseline failure. Local hooks initially failed because husky.sh was absent after ignore-scripts dependency install; generated the ignored helper, then used HUSKY=0 for commits after explicit checks to avoid unavailable/unrelated local hook tools. No source/test bypass was committed.

## Security disposition and publication boundary

Dependency manifests/lockfiles are unchanged. The inherited high build-tool advisory is braces 3.0.3 / GHSA-vfj7-8cjw-p6xm via Tailwind/chokidar/micromatch. It remains a repository/build-tool risk; the final image gate must prove Node dependency trees and test gems are absent. No unsupported override or advisory suppression was introduced.

n8n remains official 2.43.5 at `sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392`. Its previous advisory-level inventory and trusted-operator restrictions remain in [n8n security](n8n-security-2026-10-14.md). Compression is mitigated, not patched, by [the identity guard](n8n-compression-gate-2026-10-14.md). No claim of a fresh zero-finding n8n scan is made. Main/worker use the same required immutable image variable; worker/PG/Valkey have no host port mappings. Actual Coolify-generated routers, TLS and no alternate unguarded path remain KVM acceptance gates.

`publish_volitex_image.yml` is manual-only, requiring a full source SHA plus explicit `PUBLISH_CANDIDATE` acknowledgement. It checks successful campaign, migration and candidate workflows for that same SHA, builds/loads amd64 locally, boots/restores/restarts it, scans the same image, then logs into GHCR and pushes that exact local image without rebuilding. It records the registry manifest digest and scan artifact. The full CE baseline exceptions above are explicit release-owner dispositions, not a false successful CE check. No publication workflow was dispatched in this task.

The registered publication workflow ID is 361568763. Repository default branch is the unrelated historical develop line and does not contain this file; the UI may not expose a Run button. Use the registered workflow ID and explicit candidate ref through CLI/API after authorization, as with prior successful manual migration runs on the feature branch. Do not change the default branch or merge unrelated develop to expose a button. Actual publication dispatch/registry permissions and the registry digest cannot be asserted until the authorized action executes; if GitHub refuses dispatch, promote only the reviewed workflow definition through an authorized repository change. [GitHub trigger documentation](https://github.com/github/docs/blob/main/content/actions/reference/workflows-and-actions/events-that-trigger-workflows.md) describes registered-workflow API dispatch against an explicit ref.

Docker base tags and package repositories can move: a future rebuild is not asserted bit-for-bit identical. The publication workflow therefore reboots/scans its actual final image before pushing, captures its resulting immutable digest, and that digest must be used for migrate, web, ordinary worker and campaign worker via the shared VOLITEX_IMAGE variable. A build-manifest digest from an ephemeral non-publishing runner is not a pullable registry artifact.

## Remaining acceptance and authorization

1. Authorize image publication for the exact candidate SHA after the final build/scan/recovery and campaign gates pass. No authorization to merge/default-branch change or deploy is inferred.
2. Publish through the gated process, record and pull-verify `ghcr.io/yoanupop/volitex-ai-inbox@sha256:...`, embedded .git_sha, scan and the identical digest for all three application processes. No registry artifact currently exists for this candidate.
3. On the actual KVM: protected encryption keys and credentials; private PG/Valkey with persistent storage; n8n queue main/worker; TLS and every generated n8n router guarded, no bypass port; migration backup/compatible rollback; off-server backup restore, controlled reboot, queue/storage recovery and real alert delivery. Disposable CI does not satisfy these server gates.
4. Before client traffic: account/inbox tenant checks, signed webhook, ownership/handoff, WhatsApp and Instagram channel-specific smoke tests if sold. Existing authorized live WhatsApp/round-trip evidence is retained; no new live messages were sent here.
5. Campaigns remain disabled by default. Enable only after separately authorized small opted-in approved-template campaign, actual delivery-status reconciliation, opt-out operations and KVM pacing/resource/recovery acceptance. Never blindly resend unknown provider outcomes. Synthetic throughput is not Meta delivery or KVM capacity.

Normal automation and campaign release permissions are separate. Accepted infrastructure risk remains one shared VPS failure domain, without a zero-downtime or exactly-once delivery promise. Email/optional CRM/portal-theme baseline debt is not cleared by this WhatsApp/Instagram release assessment.

## File purposes in this integration

- `app/controllers/super_admin/instance_statuses_controller.rb`: supported Rails connection-pool migration status API; existing indentation corrected.
- `app/services/instagram/comments_service.rb`: reload trigger-populated conversation before locking.
- `spec/controllers/super_admin/instance_statuses_controller_spec.rb`, `spec/services/instagram/comments_service_spec.rb`: successful rendered status/migration data and persisted comment replay/account/display identity assertions.
- `spec/configs/schedule_spec.rb`: duplicate top-level YAML keys detected through the syntax tree, independent of newline format.
- `spec/controllers/api/v1/accounts/integrations/linear_controller_spec.rb`: faithful permitted-parameter service mock.
- `spec/requests/api/v1/accounts/base_controller_spec.rb`, `spec/controllers/api/v1/accounts/conversations_controller_spec.rb`: valid bot-to-target-inbox positive fixtures plus unmapped-bot denial.
- `spec/controllers/instagram/callbacks_controller_spec.rb`, `spec/services/instagram/comments_client_spec.rb`, `spec/services/whatsapp/csat_template_service_spec.rb`: exact subscription/query/timeout contracts; lazy fixture response for comment tree assertions.
- `app/javascript/dashboard/helper/specs/themeHelper.spec.js`: actual system-theme API mock and DOM isolation.
- `.github/workflows/verify_campaigns.yml`, `verify_candidate.yml`, `verify_migration_compatibility.yml`: automatic integrated-branch gates, same-source rendered assets, maintenance regressions and campaign migration/schema checks.
- `script/production/verify_candidate.sh`: restored campaign tables and restarted campaign worker heartbeat verification.
- `.github/workflows/publish_volitex_image.yml`: explicitly authorized, exact-SHA, build/boot/scan-before-push publication.
- This report and pointers in the existing candidate report/runbook: distinguish the current candidate from historical artifact/deployment claims.

## Exact-candidate campaign recovery and load

[Campaign lifecycle run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39027443208): **PASS**, 169 campaign/contact/consent/API/provider/health examples; 240 integrated maintenance/regression examples; 4 synthetic capacity examples; isolated Traefik/n8n ingress test. Same-source frontend assets compile successfully.

Real PostgreSQL/Redis + real Sidekiq processes + loopback fake Meta: 6 intended recipients, 6 provider calls, 5 accepted, 1 unknown, 0 duplicate calls, 0 lost pending, 5 stale jobs replayed and 5 overlapping jobs. Separate critical-queue probe latency 0.051 seconds. The ambiguous outcome is intentionally not resent.

Synthetic load uses ActiveJob's test adapter and direct dispatcher with an accelerated clock and mocked provider. Each snapshot creates one campaign dispatch chain. Five total test-adapter jobs include unrelated fixture callbacks, not five campaign chains. These are CI queue/ledger measurements, not provider delivery throughput, actual queue-wait percentiles, simultaneous public-webhook load, or KVM capacity.

| Recipients | Enqueue s | Snapshot s | Dispatch s | CPU s | Peak process RSS MiB | Dispatch p50/p95/p99 ms | Account read p95 ms | Duplicate calls |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 0.0059 | 0.920 | 19.53 | 13.90 | 353.0 | 18.0/21.5/33.6 | 0.92 | 0 |
| 2,000 | 0.0044 | 0.292 | 41.75 | 28.76 | 354.0 | 20.5/24.7/27.1 | 0.57 | 0 |
| 5,000 | 0.0034 | 0.777 | 120.43 | 67.75 | 361.6 | 22.9/31.4/36.7 | 0.55 | 0 |
| 10,000 | 0.0036 | 1.396 | 355.58 | 151.82 | 402.8 | 30.9/59.1/67.8 | 0.65 | 0 |

Observed database sizes: 26,329,615–56,892,439 bytes. Production still paces at the configured per-inbox rate; accelerated test throughput is not an authorization to send faster.

## Final image artifact and provenance — PASS

[Non-publishing candidate run 39027443215](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39027443215) completed **successfully** on the same source `45601e7ba53cfce240c7a26fe77bfa518ff8a7e5`. All three publication prerequisites (candidate, migrations, campaigns) are successful for this exact SHA; full CE status remains separately failed.

| Identity | Verified value |
|---|---|
| Build command/process | `docker/build-push-action@v6`, `docker/Dockerfile`, `GIT_SHA=45601e7ba53cfce240c7a26fe77bfa518ff8a7e5`, local load, push false; linux/amd64 |
| Build manifest digest | `sha256:b0192b02c1bf12458a4ccca91d0e7f4ef11a32b29b05ca61b8b1a856f2352094` |
| Loaded, booted and scanned image ID/config digest | `sha256:f73f7f4699ec0ba91fa1758fe46998e66d86ba93ccab73d19c5fca9c32d488a7` |
| Ruby base | `ruby:3.4.11-alpine3.23@sha256:ed7dfb6ccf31f54d33286eef060f611cfecbe03db3abffa37a999c0c7a9ba7a1` |
| Node build stage (not shipped runtime) | `node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f` |
| Scanner | Trivy 0.75.0, `aquasec/trivy@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa` |
| Report timestamp | `2026-10-17T11:31:54.954250787Z` |
| Scan result | **0 critical / 0 high / 2 medium / 1 low**, no new advisory/package/version/severity tuples compared with maintenance candidate #43 |
| Availability | Ephemeral CI build only; **no pullable registry reference exists** and no image was published |

Runtime checks executed by `bash script/production/verify_candidate.sh volitex-candidate:45601e7ba53cfce240c7a26fe77bfa518ff8a7e5 45601e7ba53cfce240c7a26fe77bfa518ff8a7e5`: exact embedded .git_sha; production Compose render; compiled manifest/assets; no Node dependency trees/test gems; Ruby 3.4.11/zlib 3.2.3; fresh migrations; web + ordinary + campaign worker boot; database/Redis connectivity; campaign queue process; shared attachment marker; disposable pg_dump/pg_restore including campaign tables; restart of all three processes; restarted campaign worker heartbeat; health and graceful stop. All passed. Entry-point checks passed (3), authenticated reply contract passed (8). This is disposable hosted CI, not Hostinger acceptance.

The unfiltered `candidate-image-vulnerabilities` JSON artifact remains attached to the run. Its metadata image ID equals the configuration digest exported by the build; the scan is for the booted final image, not an older tag. The scanner downloaded its current schema-2 database; the database artifact fingerprint/cache metadata was not retained, so an identical frozen database comparison is not asserted.

Remaining image rows are unchanged: Devise 4.9.4 CVE-2026-32700 and CVE-2026-40295 (medium; existing backport/unused-Timeoutable dispositions), and default JSON 2.9.1 CVE-2026-54696 (low; locked active JSON is 2.21.2). See the preceding security evidence for mitigation/reachability, not a claim the packages were removed. Node dependency absence was verified in this actual image; the inherited braces high audit row is not present as a shipped Node runtime dependency. No unsupported override or severity suppression was used.

## Git delivery

Code commits: `b6c799ea0e1d9bd920c907f2af487ac12f8461e0` (runtime/fixture repairs and gated candidate publication) and `45601e7ba53cfce240c7a26fe77bfa518ff8a7e5` (same-source asset setup for rendered integration checks). Both are pushed on `codex/integrated-release-candidate-20261017`. A subsequent documentation-only evidence commit does not change the tested source selection: publication must use **45601e7ba53cfce240c7a26fe77bfa518ff8a7e5**, not substitute a documentation HEAD or historical campaign artifact. The final handoff records the documentation commit SHA and remote/worktree verification.

Original remote maintenance `216ce98cc094bfb346dc9fd7767750ea339ded8c` and campaign `c67001496e145154882869f9a03d137a61d2f1bc` refs were verified unchanged. The primary checkout still has its 44 unrelated worktree entries. They are not included in this candidate.
