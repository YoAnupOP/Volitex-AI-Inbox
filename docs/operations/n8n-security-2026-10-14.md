# n8n security candidate assessment — 2026-10-14

## Release decision

**BLOCKED. No assessed n8n artifact is approved for production.** The working local integration is preserved. No production image was published, no production deployment or callback was changed, and no live messages were sent during this assessment. Do not deploy the rejected npm assessment images. The production environment example now requires an explicit N8N_IMAGE rather than presenting the older 2.40.3 digest as reviewed; Compose already rejects an empty value. Existing protected local configuration is unaffected. Compose parse verification rejected the unset image (exit 1) and succeeded with an explicit assessment digest (exit 0); this was configuration parsing, not deployment.

## Baseline and reproducible comparison

Integration parent/source at assessment start: `e092f9ab20d1c2be4719e276247cdaddee719bf4`, branch `codex/whatsapp-interactive-quick-menus`. The working tree was clean. The unrelated primary checkout was preserved.

Scanner: `aquasec/trivy:0.75.0@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa`. DB schema 2, updated `2026-10-14T07:11:52.271767627Z`, downloaded `2026-10-14T08:15:04.176548465Z`. Comparisons used the same cached database with `--skip-db-update`, all severities, vulnerability scanner only; no ignored findings.

| Artifact | Critical | High | Medium | Low | Unknown |
| --- | ---: | ---: | ---: | ---: | ---: |
| Official running n8n 2.43.4 | 13 | 72 | 112 | 29 | 1 |
| Plain npm 2.43.5 / Debian assessment | 14 | 174 | 243 | 95 | 6 |
| Same npm graph with Debian security upgrades | 11 | 170 | 237 | 95 | 6 |

Official 2.43.5 was also assessed with 13 critical and 72 high; it is not a security-cleared replacement. Running digest: `n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c`. Official 2.43.5 digest: `n8nio/n8n@sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392`.

Full critical/high installed-package inventories (each row remains unresolved unless an explicit fix or vendor-confirmed inapplicability is recorded):

- [85 baseline rows](n8n-baseline-findings-2026-10-14.csv).
- [188 rejected plain-npm rows](n8n-npm-rejected-findings-2026-10-14.csv).
- [181 security-updated npm rows](n8n-npm-security-findings-2026-10-14.csv).

Counts are package occurrences, not unique CVEs. The plain-npm increase includes Debian 4 critical/52 high, Node 10 critical/109 high, and bundled Go binaries 13 high. All are installed-image findings; lack of observed exploitation does not establish unreachability. The second assessment removes three critical and four high OS findings but leaves Node/Go blockers. Source URLs, installed/fixed versions and target paths are included in the inventories. No blanket exception or risk acceptance has been applied.

Reproduction pattern (use the exact digest/ID above, not a mutable tag):

```sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v volitex-trivy-cache:/root/.cache/trivy -v "$OUTPUT_DIR:/out" \
  aquasec/trivy:0.75.0@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa \
  image --skip-db-update --scanners vuln --format json --output /out/scan.json "$IMAGE"
```

A future updated DB scan is additionally required before release. Raw local JSON reports are in the operator's temporary verification directory; only package metadata is committed.

## Upstream investigation and disposition

[Official npm installation documentation](https://docs.n8n.io/hosting/installation/npm/) supports pinned-version npm installation. Published 2.43.5 requires Node >=24. The assessment used Node 24.21.0, OpenSSL 3.5.8. Upstream's Docker build uses curated pnpm workspace overrides; plain npm installation does not inherit them. This explains additional old `form-data` 4.0.0, `fast-xml-parser` 4.4.1/5.2.5 and `tar` 6.2.1 findings. Upstream workspace 2.43.5 instead pins form-data 4.0.6, fast-xml-parser 5.7.2 and tar 7.5.21, but retains vulnerable Handlebars 4.7.9, simple-git 3.36, shell-quote 1.9 and Nodemailer 8.0.10. The 2.44.1 beta metadata improves axios/shell-quote but retains Handlebars/simple-git/Nodemailer; it was not promoted or installed.

43 baseline Node critical/high CVEs were queried against GitHub's authoritative advisory API; 37 had reviewed advisory matches. Including the rejected npm graph, 79 Node advisory IDs were queried and 73 had reviewed matches. Per-row reviewed advisory URLs and patched-version metadata are included in the inventories. All 33 baseline Alpine critical/high package occurrences were independently matched to source-package fixes in the Alpine security database. The remainder remains scanner-reported uncertainty, not a false-positive disposition. Alpine source package fixes were checked against its [3.24 security database](https://secdb.alpinelinux.org/v3.24/main.json), including OpenSSH 10.3_p1-r1, OpenSSL 3.5.8-r0, expat 2.8.5-r0, pcre2 10.49-r0 and tiff 4.7.2-r0.

Material blockers include:

| Component | Evidence / fixed version | Exposure and decision |
| --- | --- | --- |
| Handlebars 4.7.9 | CVE-2026-106445 / GHSA-p8wg-vrv2-v86f; fixed 4.7.10; additional CVE-2026-106446 | Installed template runtime dependency; critical findings unresolved in stable and inspected beta metadata. |
| proxy-addr 2.0.7 | CVE-2026-90711 / GHSA-jqcg-44mw-7w3h; fixed 2.0.8 | HTTP proxy trust runtime dependency; unresolved. |
| simple-git 3.36 | scanner fix 4.0.1 | Installed execution-capable dependency; major upgrade requires upstream compatibility verification. |
| argv-parser 1.1.1 | scanner fix 2.0.1 | Installed dependency; major fix not forced. |
| Nodemailer 8.0.10 | advisory-dependent fixes in 9/10 series | SMTP-related runtime dependency; major fixes not forced. |
| shell-quote 1.9 | CVE-2026-102422; fixed 1.11 | Installed command parsing dependency; beta patch alone does not clear other blockers. |
| Braces 3.0.3 | GHSA-vfj7-8cjw-p6xm; no published fix in audited advisory | Unresolved production dependency; no claim of unreachability. |
| OpenSSH / Alpine libraries | source-package fixes above | Installed packages remain findings; absence of an SSH server is not sufficient to dismiss client vulnerabilities. |
| npm-only form-data / XML parser / tar / Go binaries | Full rejected inventories include paths and fixes | npm alternative increases exposure; rejected rather than overriding dependencies arbitrarily. |

Other critical/high entries remain individually listed as unresolved in the inventories. A complete application-specific reachability proof was not established for every transitive package. These unresolved installed-runtime findings continue to block approval.

### Why DHI was investigated

The official upstream Dockerfile references a public `n8nio/base` runtime and describes hardened Alpine characteristics in comments. This motivated checking DHI availability, not selecting it as a required remedy. `dhi.io/n8n:2.43.5` returned unauthorized: existence, patch status and suitability could not be verified. No private image is necessary to perform the accessible checks, no subscription was purchased, and no DHI credentials are required. Public official images remain the preferred supported path once upstream fixes and regression evidence are available.

## Rejected artifact provenance

Assessment recipe/lock are retained under `deployment/n8n/npm-candidate`, explicitly not referenced by production Compose and excluded from the Inbox Docker build context. Public base: `node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20`.

- Plain npm local OCI identity: `sha256:83f3802cf22456263d2f0f2e0de7f1c0ae889bd7b5424dd40e6791610cc9d4ad`.
- Security-updated assessment local OCI identity: `sha256:b72111881d34d9b98275fd65825a127d2ad1e3f029b2c07c5823c8bb71e06f52`.
- Recipe SHA256: `d14817fe7fc9eefe2675b1e74d2cafe7fd33e7557ddf990cf563a5d252dfd955`.
- Generated npm lock SHA256: `7a943066e32f114e0bb1b47a07fb71c57f9df1eb7b3acab6b15df3d9dcf050d6`.

The image revision label records integration parent e092f9a, while the assessment recipe was then uncommitted. Parent + recipe/lock hashes describe provenance; the label alone is not an exact committed-source assertion. These are unpublished local identities, not pullable release references.

Commands actually completed:

```sh
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
# executed inside the pinned Node image in the assessment directory
docker build --build-arg GIT_SHA=e092f9ab20d1c2be4719e276247cdaddee719bf4 \
  -t volitex-n8n-assessment:2.43.5-npm-security deployment/n8n/npm-candidate
```

Both builds succeeded; npm resolved normally without forced peer resolution or overrides. The second image was started with network disabled, no public ports, disposable SQLite, telemetry/API disabled: n8n version 2.43.5, UI HTTP 200, readiness HTTP 200, then graceful stop succeeded. This is only basic isolated boot evidence. Queue/PostgreSQL/Valkey, credential migration, full Inbox reply and restart/recovery regressions on this rejected artifact were **NOT RUN** because the security prerequisite failed. Existing local main/worker/Inbox health stayed healthy; protected state was not replaced. Prior live integration evidence applies to the original artifact only.

## Narrow application remediation

Vue was resolved to the earliest fixed 3.5.42 (manifest ^3.5.42, generated pnpm lock) for [GHSA-g2v6-rqmx-r4w6](https://github.com/advisories/GHSA-g2v6-rqmx-r4w6). A direct SSR carriage-return attribute-name regression and normal escaping test were added to CI. No n8n dependency override was made.

`pnpm audit --prod --json` changed from 3 high/10 moderate/5 low to **1 high/10 moderate/5 low**, zero critical. The remaining high is Braces, not claimed fixed. The initial 3.5.44 iteration's full Vitest run completed 3,804 passed/19 failed; all 19 failure identities match the recorded predecessor baseline (theme/appearance suites). Final 3.5.42 focused run with TZ=UTC: **40 files, 241 tests passed**. Running with the host timezone initially caused six widget date assertions; UTC rerun passed, an environment classification, not a test weakening.

Final direct tests: `node --test script/production/specs/vue_ssr_security.test.cjs script/production/specs/n8n_reply.test.cjs`: **10 passed**. Changed-test ESLint and package/lock/test Prettier checks passed. Prior full backend baseline remains 6,042 examples/34 matching failures/2 pending; no Ruby logic changed in this assessment. Final committed-source CI results are recorded separately after completion; full-suite red is not described as green.

## Upgrade and release gate

Obtain a public supported upstream n8n release whose installed runtime findings are fixed or individually defensibly mitigated. Scan its immutable digest, then back up n8n PostgreSQL and retain the encryption key before any candidate migration. Restore a copy into an isolated environment, use the same digest for main and worker, and repeat queue/worker/PostgreSQL/Valkey/auth/tenant/deduplication/handoff/retry/restart tests. Rollback after migrations requires the corresponding database backup and encryption key; changing an image tag alone is not a safe rollback.

Only then set the production N8N_IMAGE digest and repeat the application build/boot scan for the final source. Do not publish or deploy the rejected alternatives. KVM 4 operational acceptance and release gates remain separate. No extra infrastructure purchase is needed to resolve this upstream security blocker.

## Final committed-source CI evidence

Tested source: `2c0fe2020b6673c16107ee3cb45e3071854fa605`. Documentation-only delivery commits after this source do not change its artifact identity.

[Candidate CI 38554085838](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38554085838): **PASS**. Exact application build digest `sha256:bcdb8d62fdf7166c4ad5f767ec1963af5ff3528a0e4de57e6bb870e7371417db`; loaded image ID `sha256:409822c12819053542925f844e20abd42551689855935f55540c64699c3ab1ea`. Build resolved Ruby base `ruby:3.4.11-alpine3.23@sha256:ed7dfb6ccf31f54d33286eef060f611cfecbe03db3abffa37a999c0c7a9ba7a1`. Unpublished CI artifacts are not pullable registry release references.

Commands: `bash script/production/specs/entrypoint_test.sh`, Docker Buildx using `docker/Dockerfile` with GIT_SHA above and push=false; `bash script/production/verify_candidate.sh`; pinned Trivy 0.75.0 all-severity image scan followed by a jq critical/high fail gate. Build, three entrypoint checks, migration, web/worker boot, PostgreSQL/Redis/Quick Menu schema, shared attachment storage, disposable PostgreSQL dump/restore, restart and graceful stop all passed. The exact-source eight-test n8n contract CI job passed. No production publication occurred.

Final application scan: **0 critical, 0 high, 2 medium, 1 low**. Remaining Devise 4.9.4 entries: CVE-2026-32700 (fixed >=5.0.3), CVE-2026-40295 (fixed >=5.0.4); default json 2.9.1: CVE-2026-54696 (fixed >=2.19.9). Existing mitigation/reachability evidence remains in preceding production-candidate documentation; these scanner rows are retained, not claimed removed. CI used a freshly downloaded DB schema 2 from mirror.gcr.io at 2026-10-14T11:10:03Z; its cache metadata timestamp/digest was not retained. Do not assert that CI's database artifact is identical to the pinned local comparison cache. Scan JSON is retained as the candidate-image-vulnerabilities workflow artifact.

[Full CI 38554085803](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/38554085803): **FAIL, baseline debt**. All 16 RSpec artifacts total 6,042 examples, 34 failed, 2 pending; failed file/line/full-description identity differences versus predecessor baseline: zero. Final Vue 3.5.42 frontend: 3,804 passed, 19 failed across three baseline theme/appearance files; failure identity differences: zero. Ruby audit passed. JavaScript audit remains 1 high, 10 moderate, 5 low. Ruby lint and ESLint remain red; final tested source 2c0fe2020's 2,086 Ruby offense identities and all 260,063 ESLint location/message/rule sequences matched the predecessor exactly. Final delivery CI lint results are retained; no Ruby or frontend application code beyond the Vue dependency/security test was modified. This is not an all-green repository release.

Remaining application Braces comes through @tailwindcss/typography -> tailwindcss -> chokidar/fast-glob/micromatch. `pnpm why braces --prod` established the build-tool dependency path. The final image verification confirms no /app/node_modules or global npm packages are shipped. This narrows application runtime exposure; it does not remove the manifest audit finding or waive build-environment risk. No published fix was available.

### Vendor-confirmed npm-only finding and genuine fixes

CVE-2023-45853 is retained as critical in raw npm image counts, but [Debian's authoritative tracker](https://security-tracker.debian.org/tracker/CVE-2023-45853) explains that bookworm's zlib source does not build the affected contrib/minizip binary. The actual security-updated assessment image contains zlib1g 1:1.2.13.dfsg-1 and only libz files; dpkg checks found no minizip/libminizip package, and /usr/lib and /usr/local/lib searches found no MiniZip library. This disposition applies to that zlib1g package finding, not other archive dependencies. No scanner exclusion was added. Even excluding that one inapplicable entry, the assessment still has 10 critical and 170 high unresolved package occurrences and remains rejected.

Debian upgrades genuinely removed perl-base CVE-2026-13221, CVE-2026-42496, CVE-2026-8376 (critical), and CVE-2026-42497, CVE-2026-48962, CVE-2026-57432, CVE-2026-57433 (high), moving 5.36.0-7+deb12u3 to deb12u4. No other critical/high remediation is claimed from that candidate.

Local comparison raw-report SHA256 checksums:

- Official baseline: f2dd633835b662e4cebede66615f9fb869dea2f92076df0c11ef20e1ffdbbe70.
- Plain npm: b551e81a178819f859000979a888fd2c07b3957545e72480f1ac4354239c58b9.
- Debian-updated npm: 1ef5096945bcd582a04a544f652fb19cdb30bd538a4e9278da68394402699781.

**Remaining release blocker:** no compatible, supported public n8n artifact with a defensible critical/high runtime disposition has been established. Upstream fixes or a separately reviewed source-patching decision and full queue/database/workflow regressions are required. Original live integration remains working, but functional success does not resolve this security gate. DHI, paid infrastructure, production deployment and extra live messages are not required for the remaining offline investigation.
