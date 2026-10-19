# n8n security disposition refresh — 2026-10-19

## Outcome: FAIL — material applicability remains unresolved

The application publication is unchanged. This is a scoped n8n security assessment, not a production deployment or acceptance. No risk is accepted on the operator's behalf. The newer official stable image fixes many recorded dependencies and passes a synthetic queue regression, but neither assessed image has an adequately evidenced disposition for all material remaining attack paths. Do not select a production N8N_IMAGE merely because its count decreased.

Baseline repository: `3c83658129b38045cb067764c156b889ad0c8788`. Assessment branch: `codex/n8n-disposition-20261019`; separate worktree. Application source66, published Inbox digest, original branches/worktrees and running staging integration were preserved. Changes are documentation/inventory only; no dependency, Compose, workflow, credential, callback or production change.

## Exact artifacts and fresh scan

| Image | Immutable index digest | Critical | High | Medium | Low | Unknown |
|---|---|---:|---:|---:|---:|---:|
| Intended assessed n8n2.43.5 | `sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392` | 13 | 73 | 113 | 29 | 1 |
| Isolated official stable candidate2.43.7 | `sha256:3db21366be1d3c77c1708963129c051948573019659e8873e0294be035ffc1b2` | 11 | 35 | 93 | 27 | 1 |

Both use public `n8nio/n8n@digest` references on Docker Hub. Candidate amd64 manifest is `sha256:aaa5cd750a76ba08d7611b15df2e3521122d5d7846b15648656ad0db704ce7b6`. Alternate `docker.n8n.io` registry inspection timed out; its current candidate equivalence was **not verified**. No private/DHI authentication, custom image or publication was used. DHI branding inside official public baseline is not proof of patch completeness.

Trivy0.75.0 pinned scanner: `aquasec/trivy@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa`. Fresh scan DB schema2: UpdatedAt `2026-10-19T00:45:30.553047111Z`, DownloadedAt `2026-10-19T06:56:53.689722618Z`, DB SHA256 `f77d505dd54523c782ec55930758c3a5de9fefe03c67ccded62597df795672bb`. Baseline scanned first; candidate used the same cache with `--skip-db-update`. Vulnerabilities only, every severity, no ignore/VEX/severity override. Cache is separate from historical frozen cache.

Raw baseline scan UTC06:57:11 SHA256 `b860f423e955fde02349ec1ad71a0dbe53065cbe0fd5a35430c625aa8529ee9b`; candidate UTC07:00:54 SHA256 `f776907dade2875d512c7af35ec6442f8dc3118b4021a51d652a034eca88757f`. Local files `current.json` and `candidate-2437.json` under workstation temp `volitex-n8n-disposition-20261019`; these are local evidence, not remotely archived CI artifacts.

Compared with the old85-row inventory, baseline adds one high **libexpat2.8.3-r1 / CVE-2026-77214**, scanner fixed2.9.0-r0; upstream describes an unchecked XML_ParseBuffer length leading to over-read. Medium count also rises by one. These are refreshed database results against unchanged image, not a code regression. No installed critical/high package/version/advisory triple from the previous inventory was silently discarded.

## Complete finding-by-finding inventory

[n8n-disposition-inventory-2026-10-19.csv](n8n-disposition-inventory-2026-10-19.csv) contains **132 occurrence rows**: all86 baseline critical/high and all46 candidate critical/high. Each records exact image/version, package/version/path, advisory/severity, scanner fixed version, primary advisory/range, presence, reachability limits, required action, residual risk and candidate comparison. OS source-package fan-out is retained, not called separate demonstrated exploits.

Fresh GitHub advisory retrieval covers all57 identifiers from previous inventory plus the new Expat identifier. OS package fix metadata was refreshed from Alpine3.24 security DB. No withdrawal found in fetched advisory records. Affected package presence is established by exact-image package inventory; an advisory version match alone is not proof of execution through a customer request. Not every upstream comparator was re-evaluated programmatically in this run; range strings are preserved and the earlier range-validation evidence remains distinct. The CSV intentionally retains unresolved rows rather than fabricating closure.

### Material attack-path disposition

| Component/advisory family | Exact evidence and attack prerequisites | Disposition / minimum action |
|---|---|---|
| compression1.8.1 / CVE-2026-87776 | Baseline abstract-server.js installs compression before raw-body reader/auth. Repeated isolated Traefik test passes; guard overwrites every negotiation variant and observes zero guarded native compressor allocations. | **Verified narrow mitigation**, contingent on no bypass. Candidate actually resolves compression1.8.2; do not remove guard from intended deployment until replacement approved. |
| proxy-addr2.0.7 / CVE-2026-90711 | Request-address middleware present. Numeric proxy-hop trust differs from advisory's IPv4-mapped IPv6 subnet trust prerequisite; global address-sensitive caller proof incomplete. | Not a demonstrated unauthenticated bypass here; candidate package fix2.0.8 removes reported finding. Compression guard is unrelated. |
| Handlebars4.7.9 / CVE-2026-106445 and106446 | Candidate retains version. Core mailer reads UTF-8 file then compile(markup); express engine sets helpers without allowProtoMethodsByDefault. First advisory requires permissive prototype methods; second concerns malicious AST input. | **Those inspected calls do not demonstrate the exploit prerequisites.** No complete bundled/workflow compiler input proof, so no global clearance. Vendor4.7.10 or review every enabled template/AST entrypoint and options. |
| simple-git3.36.0 / CVE-2026-102826/27/28; argv-parser1.1.1 /102829 | Candidate retains affected versions. Core enterprise source-control/promotions invoke Git; HTTPS config permits unsafe credential helper. Actual enabled/license/module and user-supplied Git/config/environment paths not globally bounded. | **Unresolved**, not confirmed public-webhook RCE. Need supported simple-git4.0.1/parser2.0.1 or verified exclusion of advisory-specific command/config/editor prerequisites for all enabled Git consumers. |
| OpenSSH10.3_p1-r0 / CVE-2026-59999/60000/60002 | Both ssh and sshd binaries present. Compose starts n8n, not sshd, no container SSH port. Seven subpackage critical occurrences map to one advisory. SSH client may contact hostile servers through Git/SSH nodes. | Inbound SSH server path is not configured; **client exposure unresolved**. Vendor10.3_p1-r1 or enforced, tested absence of affected outbound operations. No inbound port22 is not client mitigation. |
| OpenSSL libcrypto/libssl3.5.7-r1 / CVE-2026-14456 | Advisory specifically concerns OpenSSL QUIC listener. Intended route is Traefik TLS to n8n HTTP; no n8n QUIC listener configured. | Specific QUIC prerequisite absent from intended app route; actual listener inventory pending. Do not generalize to all TLS or host proxy packages. Vendor3.5.8-r0 exists. |
| Expat2.8.3-r1; PCRE2 10.47-r1; TIFF4.7.1-r0 | Native XML/regex-JIT/image processing prerequisites. Node RegExp is not PCRE2, Node XML is not automatically Expat. Inventory does not prove relevant native binary consumers absent. | **Unresolved native consumer paths**, not demonstrated direct webhook exploits. Vendor fixed versions per CSV or binary/caller proof for the approved workloads. |
| Nodemailer8.0.10 / CVE-2026-82659 and two address-parser GHSAs | Raw mail option/file access and malicious address lists are different prerequisites. SMTP/core mailer and mail nodes exist; custom reply sends no email. | **Unresolved** beyond custom test flow; vendor9.0.1/9.1.0/10.0.6 per row or prove affected options/input unreachable/bounded. |
| braces3.0.3 / CVE-2026-93687 | Deep nested pattern expansion required. Fresh advisory records no patched version; no complete enabled glob/watch/pattern call proof. | **Unresolved**, require vendor-supported control or bounded caller proof; no arbitrary override or blanket trusted-editor waiver. |
| toml3.0.0 / CVE-2026-63376/77465 | Untrusted TOML parser prerequisite; custom reply parses JSON, not TOML. Other node/import consumers not excluded. | **Unresolved** outside test flow; supported4.1.2/4.2.0 or verified no affected untrusted parsing. |
| Axios, xmldom, ZIP, brace-expansion, URI, gRPC, MCP, editor/SSR/maps/WebSocket rows | Preconditions vary by adapter, parser, editor interaction and caller. All remaining exact occurrences and prerequisites are listed separately in CSV. | Candidate removes31 distinct baseline critical/high package/advisory pairs with **no added pairs**. This is installed-version/scan improvement, not exploit reproduction. Candidate package inventory versions are recorded in CSV. |

Candidate remaining count: **34 OS occurrences (7 critical/27 high), 12 Node occurrences (4 critical/8 high)**. Four Node criticals are two Handlebars entries, one simple-git and one argv-parser. Counts do not decide reachability; unresolved input/caller evidence decides the FAIL. No finding was dismissed solely because a trusted operator must author a workflow.

## Upstream-supported update assessment

Latest stable API identifies official2.43.7 (not prerelease), published Oct16. Source CLI manifest declares compression1.8.2; workspace overrides include proxy-addr2.0.8 and shell-quote1.11.0 while retaining Handlebars4.7.9 and simple-git3.36.0. Exact candidate image package inventory confirms the partial fixes; local package resolution confirms compression1.8.2 and Handlebars4.7.9. No blind version bump.

2.43.6 release notes describe per-request XML parser construction; 2.43.7 adds suspension of in-flight production executions on worker shutdown. Those vendor statements do not guarantee every interrupted side effect is safe to replay. No production data migration or encrypted credential reuse was attempted. The candidate's current residual findings prevent recommending it as security-cleared replacement.

Proposed production/configuration diff: **none**. Do not change the blank production N8N_IMAGE gate, staging version or the reviewed Inbox image. Candidate digest is assessment-only. No full authenticated Inbox reply, cloned real workflow/credential migration, old-to-new DB upgrade/downgrade or crash-mid-side-effect regression was executed for2.43.7; no compatibility claim beyond the probe below.

## Executed verification

- Fresh baseline and same-DB candidate Trivy scans: completed; detection results above, not security passes.
- `node --test script/production/specs/n8n_reply.test.cjs`: **8 passed/0 failed**. Auth/timestamp/raw bytes, foreign tenant, human ownership, service window, stable delivery key and bounded request behavior. Mocked request contract, not candidate-engine Inbox round trip.
- `node --test script/production/specs/n8n_compression_ingress.test.cjs`: **1 passed/0 failed** against exact baseline digest and pinned Traefik. Bounded no-exhaustion test; guarded allocation path only.
- Existing `script/production/verify_n8n_queue.sh` with candidate digest: **PASS**, disposable prefix `volitex-n8n-probe-disposition2437oct19`. Fresh PostgreSQL migrations, main readiness, workflow import/activation, queued webhook timeout with no worker, success after separate worker startup, persisted successful execution count, graceful full main/worker/PostgreSQL/Valkey restart and a further successful webhook. The script explicitly does not prove production HMAC workflow or Inbox/Meta delivery.
- Read exact image abstract-server, Handlebars engine/mailer and Git service call sites via network-disabled disposable containers. First grep used unsupported BusyBox --include option; rerun with find/grep supplied actual evidence. No claim the failed lookup established absence.
- Alternate official registry request timed out; Docker Hub pull and digest inspection succeeded. No private credentials were requested.
- No broad application suite rerun: no app/runtime source changed. Existing source66 tests and publication are not reclassified by this work.

Probe containers/networks shut down using existing test cleanup; its new named test volumes retained. Existing staging n8n main/worker/PostgreSQL/Valkey remained running. No user volume deletion, Docker prune/reset, live message, callback mutation or production action.

## Deployment control assumptions and limits

`deployment/n8n-queue.compose.yaml` uses required immutable image variables shared by main/worker, queue mode, private dependencies, no host ports, main container expose5678, identity middleware shorthand, persistent data, AOF/everysec/noeviction, bounded logs and health checks. Environment example sets public API disabled, community packages disabled, environment/file restrictions and SSRF protection. They reduce particular surfaces; no evidence makes them universal dependency fixes.

Runbook allows only administration SSH/HTTP/HTTPS and requires no public3000/5432/6379/5678, trusted operator editor and no customer workflow-authoring access. Actual Coolify generated routers, firewall, external port scan, HTTPS, backend header and every alternate route are **not tested on KVM**. No existing host firewall was changed. A file-provider label alone is not deployed enforcement. Incoming custom webhook HMAC is checked inside the node and cannot protect middleware that executes earlier.

## Minimum condition to change outcome

Either a supported official artifact must integrate remaining applicable fixes and pass the same scan/compatibility checks, **or** each remaining material prerequisite in the inventory must be excluded/controlled across the actual approved enabled node/module/workflow paths with reproducible evidence. Particular outstanding questions are Git command/config/environment reachability, all template compiler inputs/options, untrusted mail raw/address parsing, TOML/nested-pattern parsing and native binary consumers. These are specific input-boundary questions, not a demand for zero scanner findings. A single safe test workflow does not answer them for the managed platform.

No founder decision to accept unexplained critical/high exposure is requested. Keep first-client security gate open until evidence supports conditional acceptance or PASS. A newer image exists and materially improves dependency state; it does **not yet** meet that criterion. KVM purchase is not required to close this security disposition.

## Evidence retention and primary references

57-advisory snapshot SHA256 `089f0ae233032cb60599d7c6031ae43d0e68bc8c3784793474df3b872a7953dd`; queue log `cd7d24498f11c8dd2d8cbac9e31cbd1299097c89152d3acf120383d9e9cab408`; ingress log `9bc1a7abd33b475a608e2895c486d2e7632a6469e7d9bf3e791b56bd3ced7d9f`. Raw local evidence remains in the named temp folder; final per-finding inventory and this report are committed. No secrets/customer data are included.

- [Official2.43.7 release](https://github.com/n8n-io/n8n/releases/tag/n8n%402.43.7)
- [Official2.43.6 release](https://github.com/n8n-io/n8n/releases/tag/n8n%402.43.6)
- [Tagged CLI manifest](https://github.com/n8n-io/n8n/blob/n8n%402.43.7/packages/cli/package.json)
- [Tagged workspace](https://github.com/n8n-io/n8n/blob/n8n%402.43.7/pnpm-workspace.yaml)
- [Alpine3.24 security DB](https://secdb.alpinelinux.org/v3.24/main.json)
- [Compression advisory](https://github.com/advisories/GHSA-vc2v-76pw-4v95)
- [Handlebars prototype-method prerequisite](https://github.com/advisories/GHSA-p8wg-vrv2-v86f)
- [Handlebars AST advisory](https://github.com/advisories/GHSA-8r5x-fm3f-whwj)
- [simple-git trailer command issue](https://github.com/advisories/GHSA-x6jw-m9v5-85vh)
- [No-fix braces advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm)
- [Added Expat advisory](https://github.com/advisories/GHSA-8xfx-9m5m-pgcp)

Each other primary advisory URL is included in the inventory. Prior reports remain historical; this refresh supersedes claims that stable2.43.5 is the latest available or that no stable compression-patched image exists. It does not supersede previous live integration evidence with a fictitious new live test.