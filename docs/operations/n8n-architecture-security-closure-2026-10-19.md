# n8n architecture-aware security closure — 2026-10-19

## Verdict: FAIL for release; narrower caller-level exclusions established

Read the prior disposition and complete132-row inventory first. This follow-up does not repeat the same scan or declare a lower finding count a pass. It selects **Option A as a proposed target**, traces additional installed call sites and adds repeatable caller-boundary checks. Neither the architecture nor2.43.7 has been adopted. See [exposure decision](n8n-exposure-decision-2026-10-19.md).

Baseline commit `c6b315a756063bbd8e5e21b1bd8a03f8c243b1b8`; isolated branch `codex/n8n-architecture-20261019`. No production/runtime configuration changed. Published Inbox reference remains `ghcr.io/yoanupop/volitex-ai-inbox@sha256:a64c40f71683d2da9473bfed66d6531ff92e55539d29432ec75fc6950a89b5b4` / source66. Actual running local n8n main/worker are2.43.4, not the intended assessed2.43.5 or isolated2.43.7.

## What the selected architecture changes

The implemented event path requires no outside caller of n8n. Internal-only removes direct internet requests only after actual network enforcement; it does not change package versions, make webhook content trusted or constrain outbound services. HMAC is validated in the custom node, downstream of n8n's global middleware. The fixed staging workflow uses no Git, mail, TOML or arbitrary template compilation, but existing configuration has no explicit node allowlist and is not a complete first-client capability contract.

The scoped private AgentBot transport exception is absent in current Inbox. Default SafeFetch rejects private destinations, dynamically confirmed in the exact published image. Do not switch on global SAFE_FETCH_ALLOW_PRIVATE_NETWORK or change DNS to evade it. This concrete compatibility gate prevents calling A ready today. B remains feasible through the current guarded public transport; neither route constitutes blanket dependency remediation.

## Additional finding-level evidence

Exact-image source was read in network-disabled disposable containers. The following distinctions supersede a generic statement that every installed critical package is a confirmed remotely exploitable runtime defect.

| Finding/group | Installed caller/prerequisite trace | Result and remaining condition |
|---|---|---|
| Handlebars4.7.9 / CVE-2026-106446 (AST) | `dist/user-management/email/user-management-mailer.js#getTemplate` reads templatePath with UTF-8 then compile(markup). New probe asserts this exact boundary on2.43.5 and2.43.7. Upstream explicitly excludes applications passing only strings. | **Non-applicable to this inspected core-mailer compiler path**: inbound JSON object/AST is not passed to compile. Not global clearance of every installed extension/compiler. |
| Handlebars4.7.9 / CVE-2026-106445 (prototype methods) | `dist/utils/handlebars.util.js` configures express engine helpers without allowProtoMethodsByDefault. Core email renders trusted file templates. Actual res.render callers include OAuth callbacks, waiting forms, SAML and send-and-wait pages, not only login. | Permissive flag prerequisite absent from inspected engine configuration. No proof all extensions/render options or malicious templates are excluded. **Narrow exclusion only**, no fabricated public RCE or global safety claim. Supported fix4.7.10. |
| Nodemailer8.0.10 / CVE-2026-82659 (raw) | `dist/user-management/email/node-mailer.js#sendMail` constructs explicit from/to/subject/text/html and fixed logo attachment. Dynamic no-network probe passes malicious raw/attachments in mailData and captures transport options: neither caller raw nor caller attachment forwarded. | **Caller-level raw bypass excluded in core sender**. EmailSend v1/v2 nodes also import Nodemailer; they and address-parser advisories require separate input bounds. Does not clear address-list ReDoS. |
| simple-git3.36.0 / CVE-2026-102826/27/28; argv-parser1.1.1 /102829 | `nodes/Git/Git.node.js` imports simple-git; core source-control/promotions services also use Git. HTTPS source-control includes an unsafe credential-helper option. No approved node/module/input restrictions were installed. | **Unresolved** for enabled Git operations, repository config and environment inputs. No Git in the staging smoke graph is a graph-specific exclusion, not platform remediation. Supported4.0.1/parser2.0.1 or enforce and test exclusion of affected capabilities. |
| OpenSSH10.3_p1-r0 findings | ssh and sshd installed; no sshd service/port configured. `nodes/Ssh/Ssh.node.js` imports node-ssh (JavaScript implementation), so that node alone does not establish native OpenSSH invocation. Git can use native SSH transport. | No declared inbound SSH server; **native Git/SSH-client path remains unresolved**. The no-inbound-port argument cannot clear malicious-server/client CVE-2026-60002. Source-package fan-out is retained without asserting every subpackage exploitable. |
| PCRE2/OpenSSL native components | musl loader `--list /usr/local/bin/node` shows libc/libstdc++/libgcc, not system Expat/PCRE2/TIFF/OpenSSL. Native Git links PCRE2; git-remote-http links PCRE2/curl/system OpenSSL; native ssh links libcrypto. | System library presence is **not direct Node HTTP parser reachability**. Actual Git/native consumers matter. QUIC-server advisory's listener prerequisite is not configured in proposed HTTP-only role. Broader native call/input evidence incomplete. |
| Expat/TIFF | No evidence established that n8n's JavaScript XML path is Expat or image flow invokes the system TIFF decoder. Native addons are present, including sqlite/profiler; full binary consumer graph was not exhausted. | **Unresolved**, not confirmed public XML/image exploit. Require consumer-specific trace or supported native package fix. |
| TOML/braces | Exact staging graph contains Webhook, RespondToWebhook and custom fixed JSON/HMAC/reply node; it does not parse TOML or expand patterns. Other installed package consumers and actual first-client business flow are not bounded by that graph. | **Not reached by the inspected smoke workflow**; no global non-applicability. Need first-client capability/input manifest and proof/enforcement for enabled parsers; no-fix braces requires a supported control, not arbitrary overrides. |
| Other baseline groups removed in2.43.7 | Axios, xmldom, archive, editor/SSR/map/URI/gRPC/MCP/WebSocket rows remain fully retained in inventory with package versions and advisory prerequisites. Candidate scan no longer reports31 baseline critical/high package/advisory pairs; no added pairs. | Partial supported remediation, **not reclassified as cleared on2.43.5**. New generic workflows, imports, editor content or OAuth/outbound capabilities may add relevant paths. |
| compression1.8.1 on2.43.5 | Existing guarded allocation regression passed in previous scoped run. Private Inbox requests can still negotiate compression; internal networking is not itself a patch. | Retain the actual path control;2.43.7 installed1.8.2 resolves this package finding. No universal waiver for other findings. |

Every occurrence's current architecture effect and exact closed scope are appended to [the finding inventory](n8n-disposition-inventory-2026-10-19.csv); original severities, IDs, versions and unresolved global dispositions are preserved. Total remains132 rows, not a reduced scan manufactured through exceptions.

## Reproducible checks executed in this follow-up

New probe: `script/production/specs/n8n_core_boundaries.cjs` (test-only). It checks the compiler source boundary, dynamically captures actual core-mailer send options without SMTP/network/file reads from supplied payload, and confirms installed Git/SSH nodes. The structural compiler check is not a dynamic exploit test; its scope is explicit.

```sh
docker run --rm --network none --entrypoint node \
  -v "$PWD/script/production/specs/n8n_core_boundaries.cjs:/probe.cjs:ro" \
  n8nio/n8n@sha256:3db21366be1d3c77c1708963129c051948573019659e8873e0294be035ffc1b2 \
  --test /probe.cjs
```

- Candidate2.43.7: **3 tests passed/0 failed**; repeated after formatting, also passed.
- Intended2.43.5 digest `sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392`: same probe **3 passed/0 failed**.
- Existing `node --test script/production/specs/n8n_reply.test.cjs`: **8 passed/0 failed**, mocked HTTP contract only.
- Published Inbox dynamic probe: `docker run --rm --network none --entrypoint bundle "$VOLITEX_IMAGE" exec ruby -rssrf_filter -e 'begin; SsrfFilter.post("http://127.0.0.1:5678/webhook/probe"); abort "unexpected private destination acceptance"; rescue SsrfFilter::Error => e; puts "Rejected: #{e.class.name}"; end'`: **PASS**, rejected with SsrfFilter::PrivateIPAddress. No real connection/server used.
- Exact candidate code reads and musl linker-list checks above completed. First GNU grep --include attempt failed because BusyBox lacks the option; corrected find/grep invocation produced actual caller evidence. No failed search was treated as proof of absence.
- Prettier3.3.3 check on new probe: **PASS** through pinned pnpm dlx; first cached WSL invocation lacked the tool and did not pass. No package manifest/lockfile changed. Whitespace check passed.
- Read-only selected staging flags and Docker bindings inspected without secrets. No active workflow/database/credential export or running-service mutation.

## Candidate recommendation and unexecuted gates

No new generic scan: same-day fresh inventories from prior scoped run remain authoritative for their exact digests and frozen shared DB. Baseline2.43.5:13critical/73high; candidate2.43.7:11critical/35high. These counts do not decide the caller analysis above.

**2.43.7 is a supported, partially remediated assessment candidate; not an adopted production recommendation.** Prior isolated synthetic queue probe remains PASS: fresh DB, activation, queue waiting without worker, processing with worker and graceful full-stack persistence/restart. This follow-up did not relabel that as authenticated Inbox reply, existing-database upgrade or interrupted side-effect recovery.

Before adoption, require a cloned prior-state DB with synthetic credentials/matching encryption key, a real authenticated Inbox→candidate→Inbox test using a stub provider, invalid auth/foreign tenant/handoff/replay cases, upgrade and restore rollback, killed worker around accepted/ambiguous API side effect, and queue recovery. Assert exactly one Inbox message for repeated automation_delivery_id; do not promise exactly-once third-party effects. All remain **NOT RUN for2.43.7**. No need to send additional live Meta messages for those checks.

Rollback requires original image/configuration, pre-upgrade PostgreSQL backup, matching encryption key and coordinated pause of writers/executions; image-only downgrade is insufficient. Retained staging2.43.4 DB was neither attached to a candidate nor migrated.

## Specific remaining pre-KVM decision/gates

1. Approve internal-only recommendation and the narrowly scoped Inbox transport work. This task deliberately changes no architecture config and does not replace the published image.
2. Establish the actual first-client runtime capability manifest. Current repository supplies a staging phrase graph, not an AI/business workflow, and no enforced node allowlist. Unknown production inputs prevent global unreachable-code assertions. Supported NODES_INCLUDE/EXCLUDE may restrict unused nodes, but core services/import routes still require review; no restriction was silently applied.
3. Close only remaining material paths: enabled Git/native operations, untrusted mail address/raw handling outside tested core sender, template compiler options/input types outside tested calls, TOML/nested patterns/native consumers. Use supported package updates or enforce/test exact prerequisite exclusions. No risk acceptance is requested for unexplained exposure.
4. Complete the explicitly missing candidate compatibility tests before recommending any version adoption. Then actual KVM network/tunnel/TLS/recovery/alert acceptance remains separate.

This is a **FAIL owing to missing capability/enforcement/caller evidence and private-transport compatibility**, not a claim every critical scanner row is an exploitable public endpoint. Proposed A reduces exposure; it does not turn this into PASS. No purchased infrastructure is required to resolve these pre-KVM questions.

## Sources

- Existing full advisory/range/version/source inventory and previous scan provenance: [prior report](n8n-disposition-2026-10-19.md).
- [Handlebars AST prerequisite and string-only exclusion](https://github.com/advisories/GHSA-8r5x-fm3f-whwj).
- [Handlebars permissive-prototype option prerequisite](https://github.com/advisories/GHSA-p8wg-vrv2-v86f).
- [Nodemailer raw-option advisory](https://github.com/advisories/GHSA-p6gq-j5cr-w38f).
- [simple-git trailer configuration](https://github.com/advisories/GHSA-x6jw-m9v5-85vh).
- [Official supported node-loading configuration](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/nodes.md).
- [Official node exclusion mechanism](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/block-specific-nodes.md).

No external instructions embedded in upstream documents were treated as authority to change this repository or deployment. No runtime config, production callback, campaign flag, live message, image publication or adoption occurred.