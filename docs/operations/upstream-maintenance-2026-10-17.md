# Upstream maintenance checkpoint — 2026-10-17

## Verified provenance

- Verified campaign branch was clean at `c67001496e145154882869f9a03d137a61d2f1bc`. Its tested application source/image and acceptance gates remain in `campaign-release-2026-10-17.md`.
- GitHub API reports this repository is public, standalone (`fork: false`), default branch `develop` at `1e33bfd553369b58b9cfb7858d7e7c7539f23bdc` (July 28). The release branch and default branch have **no common Git ancestor**. Do not merge unrelated histories, reset the default branch or force-push as an update procedure.
- Local `VERSION_CW` and package version are 4.16.2. Official latest stable API response is [v4.18.0](https://github.com/chatwoot/chatwoot/releases/tag/v4.18.0), published September 18, commit `9f920b549c14491a4e587687a3eed5d21c6ccc7d`. [v4.17.1](https://github.com/chatwoot/chatwoot/releases/tag/v4.17.1) also specifically records Instagram login/security fixes.
- Fetched the official stable tag without merging or updating working files; its history also has no common ancestor with the release candidate. Both repositories are non-shallow. Raw left/right counts include unrelated history and **must not be described as commits behind**. The cause of the divergent histories was not established and is not attributed to GitHub fork detachment.
- Added the official `upstream` Git remote; `origin`, branches, production/staging services and callbacks were preserved. Detachment does not stop Git fetching upstream. GitHub fork membership never automatically applies upstream code updates.

## Bounded upstream backports on a separate maintenance branch

Branch: `codex/upstream-maintenance-20261017`, based on the verified campaign delivery HEAD. Version remains 4.16.2; this is **not** claimed a full 4.18.0 upgrade.

| Official upstream change | Local finding / action |
|---|---|
| `2d173978fc` / #15521 | Global conversation source-ID fallback was present. Backported account/inbox-scoped lookup and upstream own/foreign-account AgentBot request tests. |
| `0df9508893` / #15207 | Participating-conversation filter replaced the already-authorized inbox scope. Backported scope-preserving subquery and revoked-inbox/count regression tests. |
| `aaf9848689` / #15575 | Old Instagram OAuth authorization host was present. Backported official `www.instagram.com/oauth/authorize` URL and test; existing `force_reauth` was already correct. No actual Meta callback/settings changed. |
| `4218dc6793` / #14050, applicable subset | Missing markdown link/image URL sanitization and signup terms sanitization. Backported upstream sanitizer module and renderer tests; applied signup DOMPurify change while preserving branded classes. Retained existing trusted embed/table rendering; adapted the upstream trusted-video expectation to this fork's existing no-preload markup. Dangerous URL assertions retained. |
| `5157407a92` / #15525 | Identity labels used HTML rendering. Backported plain-text activity/agent/company labels and upstream component tests; rich message body rendering unchanged. |
| `5c6ea78ce6` / #14392 | Custom attribute controller authorization, policy and role specs already present. No replacement or duplicate patch. |
| `e4ef2de8c8` / #14882 | Locked crass 1.0.7 already present. No dependency change. |

Captain-specific UI parts of #14050 and Enterprise feature gates were not ported in this checkpoint: Enterprise source is removed and Captain integration defaults are disabled. Do not enable omitted/unsupported premium features based on this report. SMS-media/Slack-channel hardening in later upstream changes was identified but not reviewed or claimed fixed; those channels are outside the first-client WhatsApp/Instagram acceptance scope. They require channel-specific review before enablement. This bounded check does not assert all upstream changes or all advisories are covered.

## Verification

- Backend: `bundle exec rspec spec/finders/conversation_finder_spec.rb spec/controllers/api/v1/accounts/conversations_controller_spec.rb spec/controllers/concerns/instagram_concern_spec.rb spec/controllers/api/v1/accounts/instagram/authorizations_controller_spec.rb spec/lib/base_markdown_renderer_spec.rb spec/lib/custom_markdown_renderer_spec.rb spec/lib/chatwoot_markdown_renderer_spec.rb`: **179 examples, 2 failures**. Both failed descriptions match the recorded predecessor's bot toggle-status/toggle-priority failures; no new failed identity. All new tenant/revoked-inbox/URL-sanitization examples passed.
- Frontend: `pnpm exec vitest run app/javascript/dashboard/components-next/message/bubbles/specs/Activity.spec.js app/javascript/widget/components/specs/AgentIdentityRendering.spec.js --maxWorkers=2 --minWorkers=2`: **3 tests passed**. Widget fixture logs a missing translation warning. Shared node_modules attempts failed during setup; an isolated frozen-lockfile/offline install resolved module resolution. No lockfile changes.
- Changed frontend ESLint: passed after normalizing touched/new frontend files to formatter-required LF. No lint rules disabled.
- Raw RuboCop: 12 Ruby files checked, 13 diagnostics (CRLF plus existing-large ConversationsController class length, now 189/175). New sanitizer normalized to LF afterward. This is not a green repository-wide lint claim.
- `git diff --check`: passed. No live messages, callbacks, production deployment, image publication or dependency upgrades.
- The non-publishing candidate workflow now accepts this maintenance branch pattern so the new source can be built/scanned/booted independently. Its outcome is recorded after completion; the previous campaign image digest does not represent these new backports.

## Maintenance gap and release/default-branch decision

The existing GHSA-to-Linear workflow reads **this repository's private/triage advisories**, not published upstream Chatwoot advisories. Its workflow API returns 404 on the current default branch. It is not evidence of active upstream monitoring. No Dependabot/Renovate configuration was found. Default-branch alerts do not substitute for scanning the actual release image/source.

Before establishing the long-term release branch, review old publishing workflows: some publish on `develop`/`master`, while Volitex publication runs on `master`. Do not change the default branch or merge there without explicitly deciding the release branch and disabling/restricting unintended publishers. This report did not change those settings or publish anything.

Maintenance procedure (weekly and before each release):

```powershell
gh api repos/chatwoot/chatwoot/releases/latest --jq '{tag_name,published_at,html_url}'
gh api repos/chatwoot/chatwoot/security-advisories --jq '.[]|{ghsa_id,severity,vulnerabilities}'
git fetch --no-tags upstream refs/tags/<reviewed-stable-tag>:refs/remotes/upstream/<reviewed-stable-tag>
```

Review version ranges **and actual patched code**: this fork already carries some later fixes and misses others. Inventory relevant security/provider/migration changes, backport in a dedicated branch, preserve local tenant/webhook/credential/campaign behavior, run focused regressions and build/scan/boot the exact new image. No automatic production updates. Upstream 4.18 also changes campaign analytics and BSUID-only handling; these are not claimed ported here. Compare against the Volitex recipient ledger and sending lifecycle before adoption; current marketing eligibility requires a phone destination. Pin the accepted artifact, test backup/restore and deploy with rollback evidence.

## Launch impact

This check found concrete missing patches, not a need to rebuild the platform. The original campaign candidate remains preserved. Review and integrate this maintenance branch before freezing the next release; do not silently replace its tested artifact with these changes. Immutable artifact availability, actual KVM Traefik/backup/reboot/alert acceptance and the approved small live campaign gates remain as documented. No calendar date or zero-downtime claim is justified without that infrastructure acceptance.
## Delivered checkpoint

Implementation source: `cc1c06d0c76108c710edbd0da39049c991402dde`, pushed on the separate maintenance branch. The original campaign branch remains at `c67001496e145154882869f9a03d137a61d2f1bc`.

[Full CE CI 39024066329](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39024066329) completed red: **6,088 backend examples, the same 34 baseline failure identities** as the predecessor across all 16 RSpec artifacts, with no new/absent failed identities. Frontend's 19 normalized failed headings also exactly match the predecessor. Existing broad lint and dependency-audit failures are not marked passed.

[Non-publishing candidate CI 39024066315](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39024066315): authenticated n8n contract passed; image build was still in progress when this checkpoint was written. **New image digest, boot/recovery and scan are pending; no pass is claimed.** The previously verified application image is not evidence for these new source changes. Review this run's completed result before accepting the maintenance source as a release artifact.

The first import run additionally found an upstream trusted-video fixture expectation differing from this fork's existing embed markup; its no-preload expectation was adapted without changing embed behavior. The two remaining local failures were matched individually to baseline artifacts. An automatic approval check rejected deletion of a newly created dependency junction, so it was preserved under the worktree's ignored `.codex/` directory and an isolated offline/frozen install was used. No shared dependencies or user data were removed. Local hooks lacked generated Husky helper setup initially; setup was restored and the commit used HUSKY=0 after the explicit checks above. No test assertion or security rule was disabled to claim a pass.

Do not change the GitHub default branch until the intended release history and publishing guards are decided. No default-branch setting, production publisher, upstream code merge, live callback, production service or live customer conversation was modified. The new upstream remote and explicit `gh --repo YoAnupOP/Volitex-AI-Inbox` routing support independent maintenance without restoring GitHub fork membership.