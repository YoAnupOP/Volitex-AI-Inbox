# n8n security remediation — October 20, 2026

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
