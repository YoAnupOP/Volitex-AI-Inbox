# Quick Menu verification and release assessment

Audit date: 2026-10-11. Branch: `codex/whatsapp-interactive-quick-menus`.
Starting feature commit: `c737d593874f652334b0aa1928d3b887f2ef090b`.
Comparison base: `452f849bc5d2c45b682dcc1e1e4d44ca43c102a9`.

## Verdict

Ready for feature code review. Not ready for an unconditional merge, release
candidate, or production release: application CI and dependency scanning fail.
The seven failures from the implementation report are now conclusively
classified as seeded-test-environment failures, with reproductions on both
branches. This does not clear the other CI failures.

The original checkout on `master` contains unrelated changes and was untouched.
The existing feature worktree started clean, its four existing commits were
preserved, and its initial HEAD matched the remote branch. No additional feature
commits existed at the start of this audit.

## Fixes and audit findings

- `QuickMenusController#quick_menu_params` previously stripped unexpected item
  keys before model validation. It now accepts only the top-level name/body/items
  fields while preserving the raw JSON item shape for strict model validation.
  Request tests reject extra keys, strings, objects, and null items.
- The picker clears old results while loading and disables menu choices when
  `canReply` becomes false while the picker is open. Its send handler checks that
  state as well as the submission lock. Tests cover loading, duplicate clicks,
  a changing window, and authoritative server rejection.
- Added administrator create/update/delete and form validation component tests;
  agent mutation rejection, account/inbox access, invalid saved menu, and message
  builder rejection request tests.
- Added a window regression with an older inbound message inserted later. The
  existing Message default scope already orders by `created_at`; the shared
  window implementation was left unchanged after verifying this behavior.
- Newly introduced Ruby files use LF, resolving their introduced EndOfLine
  offenses. Existing source line endings and lint rules were retained.
- The required list section label has an explicit English default when the
  current locale lacks its translation. A Spanish-locale serialization regression
  checks the section label, open-button limit, and exact row IDs/titles. This late
  check is distinguished from the completed 102-example local batch below; its
  final verification result is recorded in the execution's final response.
- The new send endpoint bypassed the normal message controller's n8n ownership
  gate. Quick Menu send validation now uses the same owner attribute and existing
  ownership-service constant, returning `automation_owned` until human takeover.
  A request regression checks that no message is created while n8n owns the
  conversation and that sending works after the existing handoff service runs.
  This late check also requires separate final verification because Docker became
  unavailable after the completed local batch.
- Send IDs now use scalar strong parameters before lookup. Array/object IDs would
  otherwise make ActiveRecord return an array or reject the lookup with a server
  error. The existing invalid-request regression also covers these malformed IDs.

CRUD uses account-scoped queries and the existing Pundit context. Agents can read
their account's menus; administrators can mutate them. Conversation lookup uses
the authenticated account's display IDs and existing conversation authorization.
Send validation checks the menu, conversation, inbox, and channel account IDs,
Cloud provider, and existing authoritative `Conversation#can_reply?` service.
It preserves the existing n8n/human ownership restriction. Pundit remains the
account/conversation authorization mechanism; ownership is a message-send business
rule matching the ordinary message endpoint.
An account-local display ID collision resolves only to that account's conversation;
it is never a global conversation lookup.

Sending reuses `Messages::MessageBuilder`, agent attribution, outgoing history,
and normal asynchronous delivery. The creation endpoint returns 201 when the
message is created; later provider failures use the existing message failed
status/external error path, rather than pretending delivery was synchronous.
Provider failure status tests passed in the Cloud suite. Builder validation
failure returns a structured `message_rejected` error.

Saved bodies are nonblank and at most 1,024 characters. There are 1–10 items,
strict title-only objects, normalized unique nonblank string titles, and limits
of 20 characters for 1–3 reply buttons or 24 for 4–10 list rows. Values are
`qm<menu-id>_<one-based-index>`; titles remain exact. Lists use the English
`Options` section label and existing localized open-button label capped at 20
characters. The explicit default supplies the English section label even when
locale fallback is not configured. No inbound processing, webhook, n8n,
ownership, website-widget, attachment, or ordinary-text code was changed.

The current message Form bubble is the agent renderer for input_select; no
additional legacy input_select renderer was found in the dashboard component
tree. Its list items have no interactive action. Malformed input tests and widget
regressions passed. Theme tokens and long-title wrapping are present; visual
browser/dark-mode screenshots were not performed.

## Original seven failures

All seven reproduced on the seeded feature and seeded base databases. The
unseeded base run passed 49 examples; the unseeded final feature batch passed
102 examples. No assertions were weakened, tests skipped, or production behavior
changed to suppress these failures.

| Original example | Seeded cause and evidence | Clean result |
| --- | --- | --- |
| window service:88, Facebook 5-day HUMAN_AGENT | Seed creates stored `ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT=false`; GlobalConfigService reads it before test ENV=true | Pass on both |
| window service:228, Instagram 5-day HUMAN_AGENT | Stored `ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT=false` overrides test ENV=true | Pass on both |
| window service:306, Instagram 24-hour edge | Despite its description saying disabled, example sets ENV=true and expects the 7-day window. Stored false selects the strict 24-hour boundary | Pass on both |
| incoming Cloud:44, valid attachment/contact | `Contact.all.first` sees seeded `jane`, rather than the newly created Sojan Jose contact | Pass on both |
| incoming Cloud:54, attachment reauthorization | Same seeded contact assumption | Pass on both |
| incoming Cloud:136, invalid attachment | Same seeded contact assumption | Pass on both |
| incoming Cloud:237, invalid parameters | Assumes an empty contact table; seeded `jane` makes nil assertion fail | Pass on both |

Base inbound example lines are 35/45/127/228 because the feature adds a nine-line
selection-title regression. Base seeded result: 49 examples / 7 failures.
Feature seeded result before the final additional builder test: 101 / 7.
SQL inspection confirmed both stored false configuration values and first contact
`jane`. CI uses db:schema:load rather than db:seed. Use an unseeded disposable test
database for these suites; development seed data is unsuitable here.

## Executed checks

Ruby 3.4 and the checked-in Bundler dependencies ran in disposable Docker
containers. PostgreSQL was pgvector PostgreSQL 16.14; Redis was a dedicated
instance. Separate feature, base, fresh-migration, and existing-migration databases
were used. No production database was accessed. Windows bind-mounted Ruby runs
were stopped because loading was extremely slow, then rerun using Linux copies
of git archives plus the audited changes. No successful result is attributed to
an interrupted run.

### Backend

```sh
bundle exec rspec spec/models/quick_menu_spec.rb spec/policies/quick_menu_policy_spec.rb spec/requests/api/v1/accounts/quick_menus_spec.rb spec/requests/api/v1/accounts/quick_menu_sending_spec.rb spec/services/conversations/message_window_service_spec.rb spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb spec/services/whatsapp/incoming_message_whatsapp_cloud_service_spec.rb --format progress --format json --out /tmp/feature-results.json
```

Final clean result: **102 examples, 0 failures**. Intermediate runs caught and
corrected an audit-only ordering change and an accidentally removed request in
a test; neither remains in the final code. The added older-inbound test passes
with the original shared window implementation.

```sh
bundle exec rspec spec/services/conversations/message_window_service_spec.rb spec/services/whatsapp/incoming_message_whatsapp_cloud_service_spec.rb --format progress --format json --out /tmp/base-results.json
bundle exec rails db:seed
# Repeat the preceding window/inbound command on base; repeat the feature batch on feature.
bundle exec rspec spec/services/facebook spec/services/instagram spec/builders/messages/facebook spec/builders/messages/instagram spec/policies/conversation_policy_spec.rb spec/builders/messages/message_builder_spec.rb --format progress --format json --out /tmp/regression-results.json
bundle exec rspec spec/jobs/agent_bots/webhook_job_spec.rb spec/jobs/webhooks/whatsapp_events_job_spec.rb spec/controllers/webhooks/whatsapp_controller_spec.rb --format progress --format json --out /tmp/webhook-results.json
```

- Base clean window/inbound: **49 / 0**; base seeded: **49 / 7**, feature seeded:
  **101 / 7**, matching the original failures.
- Broader Facebook/Instagram/builders/conversation policy: **127 / 4** on both
  feature and base. Three failures concern Instagram comment nesting/identity;
  one locks a conversation whose display_id remains dirty. These are independently
  reproduced baseline defects, untouched by this feature.
- Agent-bot/WhatsApp webhook regression batch: **44 / 0**.

### Frontend

```sh
pnpm exec vitest run app/javascript/dashboard/components-next/message/bubbles/specs app/javascript/dashboard/components-next/quickMenus/specs app/javascript/dashboard/routes/dashboard/settings/quickMenus/specs
pnpm exec vitest run app/javascript/widget/mixins/specs/messageMixin.spec.js app/javascript/widget/store/modules/specs/message app/javascript/dashboard/api/specs/inbox/message.spec.js
pnpm exec vitest run app/javascript/portal/specs/portalTheme.spec.js app/javascript/shared/helpers/specs/BaseActionCableConnector.spec.js app/javascript/dashboard/helper/specs/themeHelper.spec.js app/javascript/dashboard/composables/commands/spec/useAppearanceHotKeys.spec.js
```

- Final focused feature: **5 files, 15 tests passed**.
- Widget/message API regressions: **5 files, 12 tests passed**.
- The four full-CI failing frontend files reproduce on base: **20 failed,
  22 passed**. An initial shared-dependency base run failed before collection due
  to Vite filesystem restrictions; its rerun used a temporary config that only
  expanded server.fs.allow to the shared worktree directory, leaving test/product
  settings unchanged. The same 20 assertions failed as CI. No test was disabled.
- Outdated Browserslist and a missing prosemirror-schema source map emitted
  warnings; they did not prevent the successful focused runs.

### Lint, formatting, and CI

Executed `bundle exec rubocop <all 19 changed non-schema Ruby files> --format simple`:
**9 offenses**: eight inherited EndOfLine findings and conversation controller
ClassLength 188/175 (base 187/175). Base controller reproduction confirmed its
EndOfLine/ClassLength offenses. Generated db/schema.rb is excluded from this
source-file assessment; an initial explicit invocation included it and produced
thousands of generated-style findings, not hidden as a passing result.

Executed `bundle exec rubocop <11 newly added Ruby files> --format simple`:
**no offenses** after fixing new EOL and one new alignment finding.
Executed `pnpm exec eslint <all changed frontend files>`: **3865 errors,
5 warnings**, dominated by inherited CRLF plus existing Sidebar formatting.
Executed `pnpm exec eslint <12 newly added frontend files>`: **0 errors,
4 Vue bracket warnings**. `pnpm exec prettier --check <12 added frontend files>`
passed. No lint rules were disabled. There is no dedicated application type-check
script in package.json. `git diff --check` passed.

[Existing complete CE CI run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38050097845)
at c737d593 was inspected through gh, including all 16 RSpec JSON artifacts:
**6014 backend examples, 68 failures, 2 pending**; frontend **3798 passed,
20 failed / 392 files**; backend lint **2099 files, 2110 offenses**; frontend
lint and dependency-security failed. Three backend shards passed, thirteen failed.
An additional base run of all 27 files containing CI failures completed **345
examples / 70 failures**. All 68 original CI failures reproduced by file/example
name with the same exception classes; 58 had identical messages. The remaining
messages differed in generated IDs/names, rendered markup, or edition metadata,
while retaining the same failing assertions. Two additional base-batch failures
concern super-admin user forms. These baseline codebase defects remain unresolved
release blockers. Full suites were not rerun locally; existing CI
provides full-suite evidence at the starting commit, not at the final fix commit.

## Migration

Executed `bundle exec rails db:create db:schema:load` for clean databases;
`bundle exec rails db:create db:migrate` on a fresh disposable database; and
`bundle exec rails db:migrate:up VERSION=20261010000000` over the base schema.
Both migration paths applied the table and recorded the version. In test mode
the following automatic schema dump failed with HairTrigger 1.0.0 calling the
removed connection.schema_migration API. `bundle exec rails db:schema:dump --trace`
reproduced the same failure on base. The failed dump partially writes a schema
file; only container copies were affected and were restored from the git archive.

Using Rails' existing production setting, `ActiveRecord.dump_schema_after_migration=false`,
the normal Rake migration tasks were invoked from rails runner in the disposable
database: down removed the table, up recreated it, migration status showed up,
and a sentinel account survived. Repeating db:migrate on the fresh migrated
database with that production setting completed successfully. These checks used
test credentials and test environment, not a production service.

Catalog queries verified the account FK with ON DELETE CASCADE, account index,
primary key, body-length/non-space constraint, JSON array/count constraint,
required fields, and timestamps. Fresh and upgraded databases reach the expected
Quick Menus schema on PostgreSQL 16, matching CI. Other PostgreSQL versions were
not executed. Full schema dumping remains a proven baseline defect.

Deployment command in the configured production runtime:

```sh
RAILS_ENV=production bundle exec rails db:migrate
```

Take and verify the runbook database backup first. Rolling this migration down
drops saved menus; preserve/export that data before considering rollback. Prefer
an approved forward fix or backup restore when data has been used. No deployment
or production migration was performed.

## Security and release artifacts

`gh api --paginate repos/YoAnupOP/Volitex-AI-Inbox/dependabot/alerts` confirmed
**161 currently open default-branch alerts: 4 critical, 87 high, 60 medium,
10 low**. These are not automatically 161 exploitable issues on this branch.
No dependency manifest/lockfile differs from base due to Quick Menus.

Critical alerts cover development shell-quote <=1.8.3 (fixed 1.8.4), development
Vitest <3.2.6 (UI server file read/execution; fixed 3.2.6, two manifest alerts), and
runtime Active Storage <7.2.3.2. The branch already locks Active Storage 7.2.3.2,
so the default-branch Active Storage alert does not establish exposure in this
candidate. Vitest is 3.0.5 and shell-quote 1.8.1; do not expose their development
servers to untrusted users. No broad dependency upgrades were made.

`bundle exec bundle-audit check --update` failed on rack-proxy 0.7.7,
[GHSA-42qh-8mx8-7wqm](https://github.com/ncr/rack-proxy/security/advisories/GHSA-42qh-8mx8-7wqm),
with scanner recommendation >=1.0.3. Its advisory title targets 1.x while the
scanner flags 0.7.7; applicability needs investigation rather than assuming either
safety or exploitability. `pnpm audit --prod --json` failed with **52 high,
41 moderate, 6 low, 0 critical** findings. Runtime/manifests include Axios,
form-data, immutable, xmldom, linkify-it and other parsing/prototype/DoS concerns;
some Node/tooling paths may not ship in browser runtime. Complete reachability
and remediation review remains outstanding. No credentials were included in code
or report.

The immutable image workflow publishes only on master push or explicit dispatch,
with github.sha tag/GIT_SHA and a digest deployment reference. No publishing
workflow was triggered. The branch's test_docker_build.yml exists locally but is
not registered in the repository's active GitHub workflows (API 404), so its
nonpublishing dispatch was unavailable. Final fix CI/push and any local image
build outcome are reported in the execution's final response; no release image
or production image reference was published or replaced. A local exact-git-archive
build from 741230468880d2582ac293788298cab6f0e238ce was attempted with GIT_SHA set
to that revision. During native dependency compilation, Docker/WSL commands became
unresponsive and the task's build clients were stopped. No successful image build,
asset precompile, runtime image boot, or artifact digest is claimed. Existing
application services and the Docker daemon were not stopped or reset. Subsequent
local Docker checks, including the late locale regression, were blocked by that
runtime condition; GitHub verification proceeds independently.

## Live WhatsApp and operational blockers

Only .env.example exists in the feature worktree. No specifically authorized
test account, authenticated agent session, Cloud test number, or n8n test workflow
was identified. Other running local services were not treated as permission to
send to their contacts. Live delivery and provider-side rejection remain unverified.

Required smoke test with a designated test account/number:

1. Administrator creates valid 3-button and 4-row menus; an agent reads but cannot
   mutate them, and another account cannot access their IDs.
2. Correct Cloud conversation shows the picker; ordinary other inboxes do not.
3. Send each menu during an open window; verify agent attribution, dashboard items,
   message status, and actual customer receipt of both formats.
4. Select every option and verify exact visible inbound titles and existing n8n
   Switch routing, including human handoff and agent/bot ownership controls.
5. Verify a normal text reply and attachments/canned responses still behave normally.
6. Verify closed/exact-boundary rejection and stale-open frontend rejection at the
   backend; try cross-account menu and conversation requests.

KVM 4 deployment, live WhatsApp, immutable release artifact verification, reboot
recovery, backup/restore, monitoring/alerts, and first-client runbook acceptance
remain outstanding. Focused passing tests do not establish production readiness.
