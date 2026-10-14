# Inbox → n8n → WhatsApp round trip — 2026-10-14

## Verdict

**Functional integration PASS; production security approval BLOCKED.** The final authenticated queue workflow produced a live WhatsApp reply, the operator confirmed receipt, and Meta reported `read`. This is distinct from the earlier direct agent text/menu verification. No production deployment, image publication, Heroku change or callback change was performed in this task.

## Exact components

- Rails source/image revision: `f0a3f1c6ca533258d2c34a6a2b9018be0c1a30b7`.
- Local application image identity: `sha256:93261f822db3a4abfefd2586277c1a3940750fe7ddf6131d059fd2bb196dc4c0`; unpublished, not a registry release digest.
- Running n8n: `2.43.4`, `n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c`.
- Newly assessed stable n8n `2.43.5`: `n8nio/n8n@sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392`. Pulled/scanned; not deployed or promoted because it retains the same critical/high findings.
- Workflow `VolitexStagingReply`, endpoint `/webhook/volitex-staging-account-1`; local account/inbox/conversation 1/3/1 and dedicated account AgentBot 1. Credentials imported privately into n8n's encrypted store; no human-agent credential in the workflow.
- Reviewed custom node SHA256: `af45f79c43ed04bd044873d69a3264e4796ada07635eea656c6eaf880b41875c`.
- Credential definition SHA256: `04f125ca2c9484543abfafe1a53f40e4b787b3a0f220dde1676721b2974fa4a0`.
- Workflow JSON SHA256: `11804b36a51500990ce974a871eeb214cc66c3ea3aa670e06e5e0165ae9af028`.

The workflow/custom nodes are mounted deployment configuration, not baked into the n8n vendor image. Their source is included in the Git commit containing this report. Subsequent configuration/documentation commits do not change the tested Rails image code.

## Findings fixed

The previously implemented automation API used `source_id` both as an idempotency key and provider identifier. Two actual defects were established:

1. A prefixed automation `source_id` made `Base::SendOnChannelService` consider the new bot message already originated from the channel and skip the first send. This caused the first live reply 23 to remain unsent.
2. Provider delivery replaces `source_id`, so a later API replay would no longer find the original automation reply.

The API now leaves `source_id` unset, looks up the immutable delivery ID in the bot's content attributes, and retains conversation locking. Migration `20261014000000` adds concurrent database uniqueness for conversation/bot/delivery ID. The query/index handles the existing JSON-coded store representation. The regression explicitly changes the original message's source to a provider ID before replaying it.

Reply 23 was guardedly repaired only in the disposable staging database, clearing its known unsent internal source marker and requeuing the same message. Its subsequent provider `read` status and operator receipt were verified. Fresh messages below prove the final fix without that repair.

## Actual final round trip and safety evidence

Timestamps below are UTC; 09:13 UTC is 14:43 Asia/Calcutta.

| Check | Result | Evidence |
| --- | --- | --- |
| Fresh Meta inbound → Inbox | PASS | Incoming message 28 at 09:13:32.725, correct staging conversation. |
| Signed Inbox event → n8n queue worker | PASS | Execution 39, sanitized worker log correlates incoming 28 and reply 29. |
| n8n → AgentBot Inbox API → Meta | PASS | Reply 29 created at 09:13:33.318; AgentBot attribution; provider `read`; operator confirmed receipt. |
| Replay with a new delivery UUID | PASS | Execution 46 returned existing reply 29 at 09:15:13.131; bot reply count remained 4 before/after. |
| Human takeover | PASS | Execution 47 returned `human_owned`; bot reply count unchanged; final conversation owner is human. |
| Direct bot POST after takeover | PASS | Actual API 422; no new outgoing message. |
| Foreign account/context | PASS | Unknown account API 404; correctly signed foreign account event 403; no outgoing message created. This complements existing cross-tenant specs. |
| Missing authentication | PASS | Actual n8n HTTP 401. |
| Invalid/stale authentication | PASS | Actual stale-header request 401; unit tests additionally cover wrong HMAC and modified raw bytes. |
| Queue worker pause/recovery | PASS with limitation | Execution 30 was `new` while worker was stopped, then `success` after restart. The 90-second probe HTTP caller timed out; recovered queue completion was verified separately. A subsequent signed non-message probe returned HTTP 200, execution 33. No provider sends in these probes. |
| API transport failure/retry | PASS | Temporarily pointed protected staging credential at an unbound local port, with automatic credential restoration. Execution 36 logged three `inbox_unavailable` attempts at 09:11:18.894/20.907/22.917; webhook acknowledgement stayed HTTP 200. Restored credential subsequently produced `human_owned` in execution 37. |
| Definite API rejection | PASS (unit) | No retry for a known API rejection; warning metadata emitted. No extra live failure messages sent. |

The final workflow separates authenticated acknowledgement from reply processing. Only indeterminate API transport outcomes are retried (three attempts, two-second spacing), using the same delivery key and fresh ownership checks. Explicit API rejection is not retried. API processing failures do not masquerade as Inbox webhook delivery failures and do not trigger automatic handoff. Exhaustion is logged without credentials or payloads; production alert delivery remains an operational gate.

Only the exact phrase `Volitex round trip` triggers this deterministic test reply. Other input/events/outgoing messages/private notes are ignored. All test recipients were the already authorized staging handset. The local conversation was returned to human ownership after testing; the published workflow remains available for controlled testing.

## Commands and verification

- `node --test script/production/specs/n8n_reply.test.cjs`: **8 passed**.
- `bundle exec rspec spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb --example 'Volitex n8n AgentBot'`: **4 examples, 0 failures** after both fixes and migration.
- RSpec AgentBot job, signed trigger, ownership service and Quick Menu sending batch: **42 examples, 0 failures**.
- RSpec WhatsApp sender, AgentBot job, signed trigger and ownership batch: **46 examples, 0 failures**. Batches overlap; these are not unique-example totals.
- RuboCop changed Ruby controller/migration: **2 files, no offenses**.
- `pnpm exec eslint deployment/n8n/custom/*.js script/production/specs/n8n_reply.test.cjs`: **PASS**.
- `pnpm exec prettier --check deployment/n8n/inbox-reply.workflow.json`: **PASS**.
- `git diff --check`: **PASS**.
- Intended Dockerfile build from exact Git archive with `--build-arg GIT_SHA=f0a3f1c6ca533258d2c34a6a2b9018be0c1a30b7`: **PASS**. Booted staging web/Sidekiq on that exact image; health endpoint `woot`. Existing storage and databases preserved.
- `bundle exec rails db:migrate:up VERSION=20261014000000`: **PASS** on disposable native test and local staging databases. Native test migration down/up: **PASS**; duplicate insert regression verifies database rejection. No production database accessed.
- Fresh disposable database `volitex_n8n_fresh_20261014`, `bundle exec rails db:create db:schema:load`: **PASS**; reflected unique automation index verified.
- Trivy `0.75.0` full vulnerability scans: application **0 critical, 0 high, 2 medium Devise, 1 low default JSON**; both n8n versions **13 critical, 72 high, 112 medium, 29 low, 1 unknown**. Application findings retain the preceding candidate's documented disposition, not a claim of zero vulnerabilities.
- Application image secret scan completed with **five findings**, not zero: four JWT matches in commented `@example` sections of the distributed AWS SDK client and one private-key fixture in `web-push`'s bundled spec. File/line context was checked without printing matches. No application credential finding was reported by this scan; this is not proof that all historical credentials are revoked.

Initial native test attempt was blocked because the disposable PostgreSQL socket was stopped; starting its existing data directory resolved that environment error. An intermediate JSON lookup was corrected after a focused regression showed the store's double-encoded representation. A concurrent scanner cache-lock failure was rerun sequentially and the n8n scan completed. None of these failed attempts is counted as a pass.

Full backend/frontend suites were not rerun in this narrowly scoped task; historical baseline failures remain documented in the preceding production-candidate report. A focused n8n contract job was added to the existing candidate CI workflow; CI completion must be assessed from the actual run, not inferred from local checks.

## Security disposition

Latest stable release 2.43.5 was discovered during this run, pulled and scanned. Its release notes do not claim remediation of the identified package advisories, and the scan confirms the same critical/high counts. There is no finding suppression or blanket exception. Full high/critical inventory: [n8n 2.43.5 scan metadata](n8n-2.43.5-runtime-advisories.csv).

| Material package group | Exposure / fixed version | Disposition |
| --- | --- | --- |
| OpenSSH 10.3_p1-r0, CVE-2026-60002 (seven package entries) | Installed runtime client/server packages; no `sshd` process observed. Fixed package 10.3_p1-r1. Client exposure depends on SSH use; absence of a daemon is not complete remediation. | Unresolved vendor image packages. |
| simple-git 3.36.0 and argv-parser 1.1.1 | Runtime Git operations; our test workflow never invokes Git. Suggested fixes simple-git 4.0.1/argv-parser 2.0.1 require major dependency changes and compatibility tests. | Not treated as harmless; no unverified forced major replacement. |
| handlebars 4.7.9 | Runtime template compilation; no vulnerable template operation used by the custom test node. Fix 4.7.10. Broader runtime reachability remains material. | Unresolved. |
| proxy-addr 2.0.7 | Runtime request/proxy address handling; relevant to public reverse-proxy deployment. Fix 2.0.8. | Production blocker. |
| shell-quote 1.9.0 | Runtime command parsing; custom workflow uses no shell invocation. Fix 1.11.0. | Unresolved image dependency; privileged workflow capability matters. |
| Other high OS/Node packages | Included in the shipped runtime image; see inventory for advisories and fixed versions. Minimal vendor image has no `apk` executable, so an in-place OS upgrade is unavailable. | Requires a supported patched vendor artifact or separately validated rebuild. |

These are installed runtime findings, not development-only dependencies. Functionality and restrictive staging routing do not prove exploitability or clear the image. The scan establishes vulnerable versions; the full exploitability assessment is incomplete. A supported patched n8n image or a tested dependency rebuild is still required before first-client deployment. No material risk is accepted on the operator's behalf.

## Remaining release gates

1. Resolve n8n critical/high runtime findings and revalidate the selected immutable artifact.
2. Review actual CI results for the delivered commits; repository-wide baseline debt is unchanged.
3. Replace the staging phrase workflow with each client's reviewed business automation and configure production failure alerts, keeping account-scoped credentials and the same ownership/idempotency contract.
4. Execute server-specific TLS, backup/restore, monitoring and reboot/rollback acceptance on the intended KVM 4. No service is declared production-ready from this localhost test.

## GitHub CI execution checkpoint

Run 38541834832 at implementation commit `de51edaa35dabc1019ee1743f44bdf59f455344c` actually executed the new `n8n-contract` job: **PASS**. The candidate build/boot job and full CE specs were still running at this checkpoint; neither is recorded as passed. Source delivery includes commits `b7fc80a704` and `f0a3f1c6ca` for the verified API fixes and `de51edaa35` for the workflow. Deployment text files were subsequently normalized to the original LF convention; this changes no workflow or application behavior.
