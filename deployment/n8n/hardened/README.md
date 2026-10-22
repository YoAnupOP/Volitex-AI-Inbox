# Maintained Volitex AI Inbox automation runtime

This image runs upstream n8n 2.44.4 with a pinned security dependency overlay and a source backport. It is maintained by this repository; it is not an unmodified vendor image or approval for arbitrary n8n nodes.

The rejected older npm assessment recipe has been removed from deployment source. Its historical findings remain in the operations evidence and Git history; this directory is the maintained build path.

## Changes

- Copy the complete application from the immutable official n8n image. Preserve upstream application code, licensing, templates, node definitions and migrations.
- Use a pinned Node 26 / Alpine 3.24 runtime instead of copying the vendor OS. Git, OpenSSH, GraphicsMagick, Expat and TIFF are not installed. Their nodes and source-control modules remain disabled by the existing operator-only HTTP/JSON policy.
- Install integrity-locked Handlebars 4.7.10, Nodemailer 10.0.9, simple-git 4.0.1, argv-parser 2.0.1 and TOML 4.2.0. Replace every physical occurrence of the old packages with links to this complete dependency closure. Retain upstream n8n's package manifest; the replacement manifest records the effective versions.
- Pin simple-git's argv-parser dependency to the security patch 2.0.1, replacing its vulnerable exact 2.0.0 requirement. No broad semver overrides or forced audit fixes are used.
- Backport a fixed 128-level AST depth bound to braces 3.0.3 parsing, compilation, expansion and stringification. Both brace/parenthesis parsing and direct AST calls are bounded. The patch fails if any pristine source hash or patch anchor differs. Package name/version and raw scanner finding remain unchanged. An independent verifier checks the four exact patched source hashes; security regressions exercise both string and AST entry points.
- Apply available same-major fixes for Hono 4.13.7, ip-address 10.7.1, Moment 2.31.0, Multer 2.4.0 and qs 6.16.0, plus Alpine zlib 1.3.2-r1.
- Backport JSON.parse-compatible own-property handling for `__proto__` to stream-json 1.9.1 Assembler (CVE-2026-104183), preserving its CommonJS API. Both ordinary and reviver paths and the actual core flatted-data reader are tested.
- Bake the two Volitex custom extension files into the image and verify their exact source hashes. Production and candidate acceptance do not mount replacement extension source from the host.
- Run as UID 1000. The deployment adds init, drops capabilities, prevents privilege escalation and limits PIDs. No npm/yarn installer is shipped.

## Database and queue companions

`Postgres.Dockerfile` uses immutable official PostgreSQL 17.11 / Alpine 3.24, applies zlib 1.3.2-r1 and uses Alpine su-exec 0.3-r0 for the entrypoint's fixed postgres-user exec. It removes the obsolete Go-based gosu executable; no database binary or data format is rewritten. `Valkey.Dockerfile` uses immutable official Valkey 8.1.10 / Alpine and applies the same zlib patch. Each has its own source marker. The initial local scans report zero known findings for both companion images; fresh CI and publication scans remain required.

For a **new deployment**, create clean volumes with these published images. For an **existing Debian PostgreSQL deployment**, stop/drain all writers, preserve backups and the encryption key, and logically dump/restore into a fresh cluster. **Never attach the old Debian PGDATA volume directly to the Alpine image.** The acceptance harness starts with the old Debian image, backs up actual n8n workflows/credentials, restores into a fresh maintained PostgreSQL volume, and then verifies signed replies and application/database/key rollback. It also migrates persisted same-major Valkey AOF state with all writers stopped and verifies string/list state before resuming queue work. Existing workstation staging volumes are not used or modified.

The separate `deployment/production/InboxPostgres.Dockerfile` supplies PostgreSQL 16.15 with pgvector 0.8.7 and pg_stat_statements preload for Inbox. It uses the same source-marker, obsolete-helper removal and scan gates, plus a checksum-pinned extension build with portable CPU flags. It is not the n8n PostgreSQL service and must have separate data, role and credentials. The extended acceptance verifies migration, vector execution, required extensions and dump/restore against this image. Existing Debian PGDATA must never be mounted directly into it.

All four maintained companion/runtime images are saved in the checksummed acceptance archive and separately scanned with no companion-image vulnerability exceptions. Publication exports `n8n/immutable-reference.txt`, `n8n-postgres/immutable-reference.txt` and `n8n-valkey/immutable-reference.txt`; use all three references in the deployment environment.

## Evidence and release gates

`Verify non-production candidate` builds this image once with the exact source marker, verifies its source and dependency closure, runs the actual node registry policy and mailer/template/parser regressions, and scans every runtime package. Its raw Trivy JSON is retained. `audit_n8n_runtime.mjs` fails every unresolved critical/high finding. The only supported retained critical/high finding is **CVE-2026-93687 in the exact hash-verified braces backport**; it is reported separately as resolved by source patch, never deleted from the raw report. The stream-json prototype backport is recorded separately too; unresolved medium/low findings remain visible in the summary.

The saved image archive is checksummed and passed unchanged to the full built-image Inbox/n8n acceptance: database upgrade, signed tenant-scoped replies, human takeover, interrupted-side-effect deduplication, queue recovery and old-image/database/key restoration. The application CE suite, migration and campaign gates are also required before publication.

Publication downloads that accepted archive, verifies its checksum/source and backport again, obtains a fresh security scan, then publishes the same image without rebuilding. The `publication-evidence/n8n/immutable-reference.txt` artifact is the production `N8N_IMAGE` value. No mutable tag or unverified local image is a production pin. Old deployment kits contain the stock runtime and are superseded only after a new verified kit is exported.

## October 22 advisory follow-up (requires a newly gated release)

The security overlay now targets MCP SDK 1.32.0, MCP server 2.3.0, follow-redirects 1.16.1, markdown-it 14.3.3, Hono 4.13.11 and sanitize-html 2.18.1. The existing backports remain verified. Upgrading the MCP packages alone does not enforce the new optional input limits (GHSA-46jr-4wx8-v453). The HTTP/JSON production policy therefore disables both `mcp` and `mcp-registry` backend modules, in addition to excluding their nodes. The registry probe must prove those modules are ineligible. Enabling MCP later requires an explicit caller review, `maxToolInputElements` and transport/parser request size limits with adversarial acceptance; it is outside this approved profile. Existing published digests do not acquire these changes.

## Maintenance

Treat upgrades as application releases. Update immutable base digests and the npm lock, review upstream API/migration changes, and rerun all gates. Remove a backport only when the vendor package contains the fix and its source/behavior is independently verified. Any unexpected vulnerable package version or changed patch source fails the build. A new advisory fails publication unless it has a concrete verified remediation.

Do not enable Git, SSH, Code, shell, image, Snowflake or other provider nodes by editing a workflow alone. They require a separate dependency/capability review. Provider and calendar/CRM integrations in the approved profile use HTTP APIs. Keep the editor private and operator-managed.

Successful CI and publication establish the release artifact's evidence. Actual KVM firewall/reboot/restore/alerts, provider credentials and client-specific workflow acceptance are still required before client traffic.
