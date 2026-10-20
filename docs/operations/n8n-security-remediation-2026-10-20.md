# n8n security remediation — October 20, 2026

## Maintained runtime follow-up

The stock-image findings below are historical evidence. The replacement candidate is now built from `deployment/n8n/hardened/Dockerfile`; the deployment example requires its **verified immutable publication reference**, never the stock image or a mutable local tag. See the [maintained runtime recipe and release process](../../deployment/n8n/hardened/README.md).

The first experimental image removed all four critical findings and nine of the ten high occurrences; the sole remaining high record is braces. That record is addressed with a source backport, including exact original/patched hashes and string/direct-AST regression tests; the original version and raw finding remain visible. An independent source verifier plus a fail-closed audit gate replaces blanket finding suppression. An additional core stream-json prototype-handling backport and available same-major request/IP/mailer fixes are included in the final candidate and require their own verification.

Initial local checks: six dependency/mailer/template/parser regressions passed, three existing core-boundary checks passed, all eighteen allowed node types and disabled modules passed. Full disposable acceptance passed against the previously verified application source `24be9585e9a0b6366dab4db6b938b19191859a79`: signed replies, invalid/foreign-tenant rejection, interrupted-effect deduplication, queue recovery, human takeover, and old-image/database/key restoration, with exactly six fake provider effects. This was an experimental locally built runtime, not a published exact-source release. Later final-image and remote exact-source results must supersede it before adoption.

Publication now consumes the same checksummed runtime archive used by acceptance, verifies its source, obtains a fresh scan and publishes without rebuilding. Remaining medium/low findings stay visible; no claim of a vulnerability-free arbitrary-node runtime is made. Actual KVM and client-provider acceptance are separate.

## Final local candidate evidence

The final experimental image reports **0 critical / 1 high / 11 medium / 1 low** against the same October 20 database. Its high braces record and one medium stream-json prototype record have exact hash-verified source fixes. The release audit reports **0 unresolved critical/high and 2 verified backports**; ten medium and one low findings remain visible, not silently cleared. Eight final dependency/core-mailer/template/parser regressions pass. The monitor, reply contract and fail-closed audit checks pass 25/25 in the Linux runtime; invoking the shell-dependent monitor suite directly from Windows failed because that shell lacked `cygpath`, so that run is not counted as a product failure or a passing check.

The final local full-acceptance run and remote exact-source gates are separate from the earlier experimental acceptance above. Publication remains pending those gates. New production Compose hardening (init, dropped capabilities, no-new-privileges and PID bound) is also applied by the CI acceptance harness.

Residual lower-severity scope: MongoDB/Redis LangChain, Markdown and related SDK/node capabilities remain outside the approved node registry. The core flatted-data reader uses the patched Assembler and plain streaming JSON parser; it does not use JSONC parsing or stream-json pick/ignore/filter/replace filters implicated by the other two stream-json advisories. Element Plus remains an operator-editor dependency; no arbitrary untrusted link/markdown workflow capability is approved. These facts are limits of this restricted profile, not proof that every bundled frontend or optional node is vulnerability-free. All findings remain in scan artifacts and upgrades still require review.

## Database/queue image follow-up

The broader n8n stack audit also found outdated Debian companion images: PostgreSQL had 2 critical/89 high and Valkey had 3 critical/56 high occurrences. These are package findings, including helper binaries, not evidence of a demonstrated live database exploit. The latest official PostgreSQL Alpine image still bundled an obsolete Go-based gosu helper. The maintained companion recipes now use official PostgreSQL 17.11 and Valkey 8.1.10 Alpine bases, apply the available zlib patch and use Alpine's C su-exec for PostgreSQL's fixed user-drop command. Local complete scans of both final companion images report **zero findings at every severity** against the same October 20 database. No suppression is used.

The release pipeline now builds, source-marks, scans and archives both companion images alongside n8n, requires full acceptance, and publishes them only after all exact-source gates pass. The full harness performs real old-Debian-to-fresh-cluster PostgreSQL logical restore and same-major Valkey AOF-state migration before authenticated replies, queue recovery, human takeover and old-application/key restoration. Production and candidate n8n custom extension code is also baked into the immutable image and checked by exact source hashes; only the legacy migration baseline mounts extension source.

The recipe and [migration boundary](../../deployment/n8n/hardened/README.md) supersede the old companion pins. Never change an existing PostgreSQL data volume's image from Debian to Alpine in place. New KVM deployments use fresh volumes. Final exact-source CI/publication evidence remains the adoption gate; local scan summaries and earlier application-only passes do not substitute for it.

## Historical stock-image assessment

## Release remains blocked

The deployment example and existing compatibility checks now select official stable **2.44.4**, immutable image `n8nio/n8n@sha256:c72fa9f1bd9b59626deeb284824c0495625c3f6d894d395d27e241bf192d9900`. This is a security upgrade candidate, **not production approval**. No running staging database or client service was upgraded. Previously exported deployment kits still contain the old image and must not be described as patched.

GitHub's release API on October 20 identifies `stable` as `release/2.44.4` and the versioned release as `prerelease: false`; 2.45.0 is a prerelease. See the [official release](https://github.com/n8n-io/n8n/releases/tag/n8n%402.44.4). The pulled image reports n8n 2.44.4 and Node v26.10.0. Its Alpine 3.24 runtime replaces the older native package set.

## Measured remediation

Both exact images were scanned on linux/amd64 using Trivy 0.75.0 and the same freshly downloaded vulnerability database. All severities were collected; no ignore file, VEX, severity override or unfixed-finding exclusion was supplied.

| Image | Critical | High | Medium | Low | Unknown |
| --- | ---: | ---: | ---: | ---: | ---: |
| Previously selected 2.43.8 | 11 | 35 | 92 | 28 | 1 |
| Upgrade candidate 2.44.4 | 4 | 10 | 31 | 1 | 0 |

**32 critical/high package/advisory identities disappear; none are added.** Historical October 19 medium/low totals differ because the advisory database changed. These figures compare both images against the October 20 database, not different databases.

Database UpdatedAt: `2026-10-20T07:17:35.368599961Z`; DownloadedAt: `2026-10-20T10:34:53.952988626Z`; database SHA256: `608feb5768b94115184d880968b7beceb70b02808852c58c8cd3e82508e60633`. Scanner/image/report identities and counts are recorded in the [safe scan summary](evidence/n8n-security-2026-10-20.json). Raw reports remain in the workstation's protected task evidence directory; fresh CI reports are uploaded as `n8n-image-vulnerabilities`.

## Remaining work

The [remaining finding inventory](n8n-security-remaining-2026-10-20.csv) retains every critical/high occurrence, installed version, scanner fix version and advisory link.

| Dependency | Installed | Scanner fix | Required remediation |
| --- | --- | --- | --- |
| libexpat | 2.8.5-r0 | 2.9.0-r0 | Official image native-package refresh |
| tiff | 4.7.1-r0 | 4.7.2-r0 | Official image native-package refresh |
| Handlebars | 4.7.9 | 4.7.10 | Upstream n8n dependency patch, including core mail rendering |
| simple-git / argv-parser | 3.36.0 / 1.1.1 | 4.0.1 / 2.0.1 | Upstream integration update across major versions |
| Nodemailer | 8.0.10 | 10.0.6 covers all retained findings | Upstream integration update across major versions, including core mailer |
| TOML | 3.0.0 | 4.2.0 covers both retained findings | Upstream integration update across major versions |
| braces | 3.0.3 | None published | Upstream fix or a separately reviewed maintained replacement/backport |

The [braces advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) still lists no patched version. A blanket `npm audit fix --force`, replacing major versions inside the vendor image, deleting package metadata, or suppressing the scanner is not evidence of a compatible fix. This change does not claim that the remaining dependencies have no possible remediation; their remediation has **not been implemented or accepted** here.

Existing private-network, operator-only, node/module restrictions remain enforced. The [historical caller assessment](n8n-restricted-profile-assessment-2026-10-19.md) explains those mitigations; they do not remove the retained vulnerable packages or satisfy the new release gate.

## Enforced release boundary

`Verify non-production candidate` now separately scans the exact `N8N_IMAGE` from the deployment example and fails on any critical/high finding. The full JSON is retained even when this check fails. Existing policy, queue, upgrade/restore, authenticated reply and interrupted-effect acceptance jobs target the new digest. Their results must be obtained for this source; earlier 2.43.8 results are not 2.44.4 compatibility evidence.

The candidate workflow is already required by automatic application publication. Therefore this security gate also blocks new publication while findings remain. A successful application-only scan, a skipped publish job, and historical published images do not clear n8n. Actual KVM and client-provider acceptance remain separate.
