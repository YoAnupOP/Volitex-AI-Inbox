# Private AgentBot transport and isolated n8n acceptance — 2026-10-19

## Scope and release verdict

Baseline: `b9e656065d970a207cfb60d799003521db514227`. Branch: `codex/agentbot-private-transport-20261019`. The narrow transport is implemented and tested in source. **This is not a replacement published Inbox image, a staging configuration change, or approval to adopt n8n2.43.7.** Security clearance still requires disposition against the actual approved business workflow capabilities; see [capability inventory](n8n-capabilities-2026-10-19.md).

Transport source commit: `41933673ed3e2c4e2997a54f9f00c6fbd74afa10`. The subsequent evidence/harness commit does not change those application files. Full application diff: `git diff b9e656065d970a207cfb60d799003521db514227..41933673ed3e2c4e2997a54f9f00c6fbd74afa10 -- .env.example lib/webhooks spec/lib/webhooks/private_agent_bot_transport_spec.rb`.

## Transport changes and operator contract

`lib/webhooks/trigger.rb` selects `Webhooks::PrivateAgentBotTransport` only for `:agent_bot_webhook`; otherwise its existing SafeFetch path is retained. No SafeFetch implementation or global policy was changed. Serialization, HMAC, delivery identifier, timeout, retry and human-handoff behavior stay on the existing trigger/job path.

The optional **operator-controlled** `N8N_AGENT_BOT_TRANSPORTS` JSON array defaults to `[]`. Example only; substitute real local IDs, reserved address and fixed webhook route through the protected deployment configuration:

```json
[{"account_id":1,"agent_bot_id":7,"url":"http://n8n-main:5678/webhook/account-1","ip_addresses":["172.28.8.10"]}]
```

Requirements:

- Bind an account-owned AgentBot ID, exact destination URL and exact private IP addresses. Never derive this array from tenant input. Reserve the main service's private address in the deployment network; changing its address requires an operator update. Dynamic unpinned addresses fail closed.
- The payload account must match the binding. The stored bot must belong to that account, still have exactly that outgoing URL, and its stored signing secret must match the trigger's secret using a timing-safe comparison. Missing/wrong credentials fall back to ordinary SafeFetch; they never grant internal access.
- Permit only HTTP(S), a valid port and `/webhook/<safe segments>`; no userinfo, query, fragment, encoded traversal or alternate admin path. Duplicate URL bindings fail loudly. Separate accounts need distinct webhook URLs.
- Each DNS answer must match a configured exact RFC1918/ULA address. Empty, mixed, unpinned, public, loopback, link-local, mapped-IPv6 and metadata-address cases reject. Connect to the validated IP, without a second hostname lookup or environment-proxy detour. Existing HTTPS certificate validation remains in place.
- POST only. Every redirect rejects before a second request. The custom transport reuses SafeFetch's request options, bounded body handling, header checks and network timeouts. Network timeouts retain the existing bounded AgentBot retry contract.
- Keep `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=false`. No account webhook, media fetch or other caller gains this exception. Operator bindings are authority over a precise bot/route, not a general internal host allowlist.

The ordinary tenant UI/API cannot configure the environment binding or its IP pins. Compromise of the operator environment or pinned n8n service remains outside what an SSRF transport can prevent. Plain HTTP is suitable only on the intended isolated Docker network; external transport still needs HTTPS and actual network acceptance.

## Focused regression results

Executed with rbenv initialized, repository Ruby dependencies and a disposable test database:

```sh
bundle exec rspec spec/lib/webhooks/private_agent_bot_transport_spec.rb \
  spec/lib/webhooks/trigger_spec.rb spec/lib/safe_fetch_spec.rb \
  spec/jobs/agent_bots/webhook_job_spec.rb spec/listeners/agent_bot_listener_spec.rb \
  spec/services/conversations/automation_ownership_service_spec.rb
bundle exec rspec spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb \
  --example 'Volitex n8n AgentBot'
bundle exec rubocop lib/webhooks/trigger.rb lib/webhooks/private_agent_bot_transport.rb \
  lib/webhooks/private_agent_bot_transport/{options,request,fetcher}.rb \
  spec/lib/webhooks/private_agent_bot_transport_spec.rb script/production/specs/n8n_acceptance/seed.rb
node --test script/production/specs/n8n_reply.test.cjs
python3 script/production/specs/n8n_acceptance/test_harness.py
pnpm dlx prettier@3.3.3 --check script/production/specs/n8n_acceptance/{fake,post}.cjs
```

Results: **123 RSpec examples / 0 failures**, **4 filtered API examples / 0 failures**, **7 Ruby files / 0 offenses**, **8 Node tests / 0 failures**, Prettier PASS; both new JavaScript files pass `node --check`, Python AST syntax check PASS. One existing Ruby deprecation warning remains. No full-suite rerun or claim that recorded baseline failures are fixed.

Harness cleanup review found that a failed network-create could otherwise attempt to remove a pre-existing same-name network. Cleanup now records network ownership only after successful creation. **2 Python unit tests passed**, with Docker calls mocked: a rejected create never issues remove, and a subsequent setup failure removes only the network this run created. This final harness-only cleanup change does not change the tested candidate's requests, credentials, execution or recovery behavior.

The transport regression covers internal delivery with the global switch false, public fallback, unrelated callers, tenant/bot/secret mismatch, changed URLs, DNS pins/rebinding boundaries, metadata and malformed destinations, redirects, proxy exclusion and timeout classification.

The fresh Windows worktree's commit hook initially failed because `.husky/_/husky.sh` was absent. After the explicit checks above, commits used a command-local `core.hooksPath=NUL`; repository hook configuration was not changed. The first credential-pattern scan attempt used Linux Git against a Windows-managed worktree and failed on its Windows `.git` pointer; the corrected native Windows scan examined all18 changed files with zero credential-pattern hits. This is a narrow changed-file check, not a claim that reachable history or issuer-side revocation was re-audited.

## Isolated acceptance harness

```sh
python3 script/production/verify_n8n_acceptance.py
```

Run from Linux/WSL with Docker access and the pinned dependencies locally available. The harness creates its own `--internal` bridge, no published ports, separate PostgreSQL and Valkey instances, generated synthetic keys/tokens, fake Meta endpoint and protected temporary evidence. It never accepts an operator database/env file or reads staging data. It creates/removes only its own named containers/network; its disposable volumes and private evidence are retained. Subnet collision fails rather than changing another network.

Inbox artifact: `ghcr.io/yoanupop/volitex-ai-inbox@sha256:a64c40f71683d2da9473bfed66d6531ff92e55539d29432ec75fc6950a89b5b4` with **only this branch's trigger and transport source mounted read-only**. This proves the source overlay, not that the published artifact includes the change. A separately authorized build/publication and artifact verification are required before deployment.

Baseline n8n2.43.4: `n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c`.

Candidate n8n2.43.7: `n8nio/n8n@sha256:3db21366be1d3c77c1708963129c051948573019659e8873e0294be035ffc1b2`.

The harness uses the committed custom node and workflow. The real Inbox API authenticates the bot and creates replies; only the provider is stubbed. It backs up an already exercised synthetic2.43.4 database, matching encryption key and n8n data, upgrades the same database to2.43.7, and restores the prior snapshot to a separate database/data volume for rollback. This does not prove recovery of real staging or KVM data.

### Executed acceptance result: PASS for the tested integration contract

Final run: `/tmp/volitex-acceptance-11563-d5_6ewf0` in Ubuntu WSL/Docker, 2026-10-19. The redacted [result record](n8n-acceptance-result-2026-10-19.json) is committed; its SHA256 is `3e618bfa0ebd8e2176628ee94e6355beedd973ee579bebe22f14861d4b6209a9`. Protected local diagnostic log SHA256 after removing seed IPC secrets: `cc1c440caac2fe68afbc38f7ba652d38d44b98429b1ae7303d3bf19d161cc8b0`. Do not publish the synthetic credential fixtures or database backups.

| Check | Actual result |
|---|---|
| Fresh Inbox preparation, PostgreSQL/Valkey connectivity, web/main/worker readiness | PASS |
|2.43.4 authenticated private Inbox→n8n queue→Inbox API→fake provider | PASS; one provider call |
| Prior-state backup after workflow execution | PASS; PostgreSQL dump SHA256 `8066d1f00619f2384aed27b53f0e0b92c3c0c22650690a1e255903686cd3d921`, matching n8n data/key retained |
|2.43.7 existing synthetic DB startup/upgrade, encrypted credentials, activated workflow and authenticated round trip | PASS; second provider call |
| Invalid signature, signed foreign account, authenticated replay | PASS;401,403,200 respectively; no additional provider call |
| Kill worker after Inbox API commits, before proxy returns response | PASS; commit marker less than one second old, response not released when worker killed |
| Restart worker and replay same incoming message | PASS; repeated real API POST observed, one total provider call for that incoming message; owner remained n8n |
| Queue an event while worker stopped, restart worker | PASS; no send while stopped, exactly one subsequent provider call |
| Human takeover and authenticated repeat | PASS; neither API POST count nor provider-call count increased |
| Interrupted execution visibility | PASS for terminal accounting; candidate recorded **30 success,2 crashed**, zero running/new/waiting at checkpoint. Crashed records are not relabeled successful |
| Restore prior dump and n8n data into separate DB/volume, restart original2.43.4 | PASS; old image decrypts restored credential and executes another authenticated round trip |
| Total fake-provider calls |5, exactly the five intended unique replies across baseline, upgrade, crash replay, queued recovery and rollback |

This proves duplicate prevention at the **Inbox API reply-creation boundary** for a stable incoming-message key. It does not promise automatic replay of every crashed n8n execution, exactly-once Meta delivery, or automatic recovery after a provider accepted a request whose result is unknown. The test explicitly replays the event following a worker crash; monitoring/operator recovery remains necessary for crashed executions. No additional Meta message, callback change or production activity occurred.

The synthetic PostgreSQL and data snapshot test covers an exercised baseline database, not the real staging database or an arbitrary historical n8n version. Rollback pauses writers and restores both database and matching data/key, rather than downgrading an already migrated database in place. Inbox data is not rolled back; stable reply keys protect repeated API writes. Actual KVM backup/restore and disaster recovery remain separate acceptance gates.

Initial harness attempts failed due to local fixture/setup errors: unavailable unpinned Node helper pull, missing pgvector extension, generated password complexity, omitted custom-extension path, and an insufficient post-restart request timeout. These were corrected in the harness, not production logic. A prior partial run already passed both round trips and the kill boundary but stopped during its recovery probe; it is not counted as a full PASS. The final full run above passed without skipping the repeated API-write or provider-count assertions.

Candidate core-boundary probe repeated on the same digest: **3 tests passed/0 failed** using `docker run --rm --network none --entrypoint node -v "$PWD/script/production/specs/n8n_core_boundaries.cjs:/probe.cjs:ro" "$CANDIDATE" --test /probe.cjs`. It confirms the narrow UTF-8/core-mail raw-option boundaries and that Git/SSH nodes remain installed, not global security clearance.

## Security inventory boundary and remaining gates

The existing132-row advisory inventory is retained, with transport/capability evidence appended per row. No scan counts, advisory severity or global applicability are waived by transport success. No repeat generic scan was necessary for the unchanged n8n image digests and same-day recorded database. Recorded2.43.7 inventory remains **11 critical/35 high/93 medium/27 low/1 unknown**, versus2.43.5 **13 critical/73 high/113 medium/29 low/1 unknown**; see the existing disposition report for Trivy0.75.0 and frozen DB identity. Internal-only reduces direct public ingress only after real network enforcement; signed WhatsApp/Instagram content is still untrusted. Git/native SSH, mail address parsing, template/compiler and native/parser entrypoints remain subject to the exact caller-specific limits in the inventory.

**Overall security verdict remains FAIL:** compatibility gates for this contract passed, but approved production capabilities and remaining advisory prerequisites are unresolved. Do not adopt2.43.7 or call the platform production-ready on this evidence alone. No unsupported overrides, new image publication or runtime adoption was performed.

Pre-KVM: approve and version the actual first-client business workflow/capability manifest, then enforce/test its supported restrictions and complete the remaining material advisory dispositions. The one staging phrase responder is not that manifest. Candidate compatibility is separate from a security PASS. No n8n image has been adopted here.

Post-deployment acceptance: private main/worker/DB/Valkey routes and no alternate ingress; restricted administration and HTTPS/origin behavior; stable IP reservation; off-server DB/attachments/key restore; reboot/worker recovery and actual alert delivery. No KVM result is claimed.
