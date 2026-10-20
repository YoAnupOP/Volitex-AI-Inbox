# Maintained Volitex AI Inbox automation runtime

This image runs upstream n8n 2.44.4 with a pinned security dependency overlay and a source backport. It is maintained by this repository; it is not an unmodified vendor image or approval for arbitrary n8n nodes.

## Changes

- Copy the complete application from the immutable official n8n image. Preserve upstream application code, licensing, templates, node definitions and migrations.
- Use a pinned Node 26 / Alpine 3.24 runtime instead of copying the vendor OS. Git, OpenSSH, GraphicsMagick, Expat and TIFF are not installed. Their nodes and source-control modules remain disabled by the existing operator-only HTTP/JSON policy.
- Install integrity-locked Handlebars 4.7.10, Nodemailer 10.0.9, simple-git 4.0.1, argv-parser 2.0.1 and TOML 4.2.0. Replace every physical occurrence of the old packages with links to this complete dependency closure. Retain upstream n8n's package manifest; the replacement manifest records the effective versions.
- Pin simple-git's argv-parser dependency to the security patch 2.0.1, replacing its vulnerable exact 2.0.0 requirement. No broad semver overrides or forced audit fixes are used.
- Backport a fixed 128-level AST depth bound to braces 3.0.3 parsing, compilation, expansion and stringification. Both brace/parenthesis parsing and direct AST calls are bounded. The patch fails if any pristine source hash or patch anchor differs. Package name/version and raw scanner finding remain unchanged. An independent verifier checks the four exact patched source hashes; security regressions exercise both string and AST entry points.
- Apply available same-major fixes for Hono 4.13.7, ip-address 10.7.1, Moment 2.31.0, Multer 2.4.0 and qs 6.16.0, plus Alpine zlib 1.3.2-r1.
- Backport JSON.parse-compatible own-property handling for `__proto__` to stream-json 1.9.1 Assembler (CVE-2026-104183), preserving its CommonJS API. Both ordinary and reviver paths and the actual core flatted-data reader are tested.
- Run as UID 1000. The deployment adds init, drops capabilities, prevents privilege escalation and limits PIDs. No npm/yarn installer is shipped.

## Evidence and release gates

`Verify non-production candidate` builds this image once with the exact source marker, verifies its source and dependency closure, runs the actual node registry policy and mailer/template/parser regressions, and scans every runtime package. Its raw Trivy JSON is retained. `audit_n8n_runtime.mjs` fails every unresolved critical/high finding. The only supported retained critical/high finding is **CVE-2026-93687 in the exact hash-verified braces backport**; it is reported separately as resolved by source patch, never deleted from the raw report. The stream-json prototype backport is recorded separately too; unresolved medium/low findings remain visible in the summary.

The saved image archive is checksummed and passed unchanged to the full built-image Inbox/n8n acceptance: database upgrade, signed tenant-scoped replies, human takeover, interrupted-side-effect deduplication, queue recovery and old-image/database/key restoration. The application CE suite, migration and campaign gates are also required before publication.

Publication downloads that accepted archive, verifies its checksum/source and backport again, obtains a fresh security scan, then publishes the same image without rebuilding. The `publication-evidence/n8n/immutable-reference.txt` artifact is the production `N8N_IMAGE` value. No mutable tag or unverified local image is a production pin. Old deployment kits contain the stock runtime and are superseded only after a new verified kit is exported.

## Maintenance

Treat upgrades as application releases. Update immutable base digests and the npm lock, review upstream API/migration changes, and rerun all gates. Remove a backport only when the vendor package contains the fix and its source/behavior is independently verified. Any unexpected vulnerable package version or changed patch source fails the build. A new advisory fails publication unless it has a concrete verified remediation.

Do not enable Git, SSH, Code, shell, image, Snowflake or other provider nodes by editing a workflow alone. They require a separate dependency/capability review. Provider and calendar/CRM integrations in the approved profile use HTTP APIs. Keep the editor private and operator-managed.

Successful CI and publication establish the release artifact's evidence. Actual KVM firewall/reboot/restore/alerts, provider credentials and client-specific workflow acceptance are still required before client traffic.
