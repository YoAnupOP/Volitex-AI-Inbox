# Readiness fixes — October 20, 2026

## Confirmed results

- Source `b72258f9d3` passed all sixteen backend test groups and the frontend suite in [CE CI 39393632580](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39393632580). The overall workflow still failed its independent lint/dependency jobs. Existing assertions now enforce this fork's branding, disabled upstream telemetry and light-only appearance; no production behavior was reverted to satisfy upstream assertions. The historical notification fixture explicitly selects its historical sender configuration.
- Ruby/JS/Vue source line endings are normalized to LF in Git. The separate line-ending commit has no non-whitespace source changes. Rake tasks also use LF for Linux lint.
- The public unknown-domain error no longer asks anyone to email an account API key.

## Follow-up changes requiring exact-source CI

- Restore helper: only query Rails `schema_migrations` when an expected Rails version was supplied. A n8n archive restore no longer fails on a Rails-only table. It still requires a separate restored n8n boot, workflow and encrypted-credential acceptance with the retained key.
- Browser/runtime dependency patches: DOMPurify 3.4.16, markdown-it 14.3.1, PostCSS 8.5.23, yaml 2.8.3, Babel runtime 7.26.10, Turbo 8.0.21 and min-document 2.19.1. Local `pnpm audit --prod --audit-level low` reports **No known vulnerabilities found** after lockfile resolution. Local Node is 22; release CI/build uses the required Node 24. Local audit/lockfile resolution is not runtime acceptance.
- Tailwind typography is used only by `tailwind.config.js`; it belongs with the build dependencies. The production Docker build installs build dependencies before compiling assets and removes `node_modules` from the final production image. Moving typography to dev dependencies does not patch or suppress the retained build-tool `braces` finding. No audit ignore list was added.
- Ruby and frontend lint fixes are reviewed separately from application acceptance. No lint/security gate is disabled.
- The full development/build dependency audit is separate and still reports findings, including the test runner's tinypool dependency. Production audit success is not a clean full-graph audit. Do not run untrusted test/configuration code or treat development tools as a production service.

## Security boundaries and remaining work

The [braces advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) lists no patched version as of this check. It remains in build tooling, where repository-controlled patterns are used. Do not compile customer-supplied Tailwind configuration or patterns. Production dependency audit success does not assert that the full development/build dependency graph is vulnerability-free.

The assessed n8n image remains the official latest release on the [upstream release page](https://github.com/n8n-io/n8n/releases/tag/n8n%402.43.8). Its critical/high findings are not patched by Inbox browser dependency updates; retain the operator-only editor, enforced node/module policy, separate databases and private network. Broader n8n capabilities require a new caller/security review.

No VPS exists yet. Host access/TLS, complete off-server DB/media/queue/key restore, independent alert delivery, reboot/recovery, measured capacity and real channel/calendar/CRM acceptance cannot be marked passed without that environment and client provider configuration. Campaigns remain disabled until their separate live acceptance passes. A single KVM is not a high-availability deployment.
