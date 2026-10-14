# Local staging resume — 2026-10-14

## Result

**Available for isolated testing; NOT READY for first-client production deployment.** No production deployment, Meta callback update or live WhatsApp send was performed.

Source checked: `1f064936eb6804dd00786fc47fc3a1dbc4c087f5`, clean feature branch and matching remote. Running application artifact remains `volitex-candidate:38229d6009cac43c86066296275ae629fd5b0d9e`, immutable local identity `sha256:65ed1483496563f13add97de1970e415e20dd43b8229a97e221db06b6218b65b`. The later source commit changes documentation only. No application rebuild was needed for this operational restart.

## Restart and cleanup

- Started staging PostgreSQL, Redis, web and n8n main; n8n worker/PostgreSQL/Valkey were already running. Automatic approval review rejected starting Inbox worker/ingress without a specific reason; the operator ran that command. Sidekiq registration subsequently verified.
- Nine staging containers remain: five `volitex-local-staging-20261013-*` services and four `volitex-n8n-local-staging-20261013-*` services. Inbox is on localhost:3400, callback-only ingress on localhost:3401, n8n on localhost:5679.
- Removed four stopped obsolete test runners, then thirteen older duplicate/test containers after explicit operator authorization. Older `volitex-ai-inbox`, `deployment` and standalone n8n containers were retired. Images and all Docker volumes were retained; no prune, volume deletion, factory reset, source deletion or production operation occurred.
- Private recovery directory: `/home/anup/.codex/runtimes/volitex-retired-containers-20261014`, mode 0700, approximately 4.3 GiB. Mode-0600 recovery configuration preserves image/volume/environment metadata. Full writable-filesystem exports preserve the old unmounted web/Sidekiq and readiness PostgreSQL containers. Mounted databases/storage remain in their original volumes. This directory contains sensitive recovery material: do not publish or copy into Git.
- Local database/inboxes remain: one WhatsApp channel, one inbox, three incoming and two outgoing messages before/after restart. No pending outbound jobs were present before worker startup; a subsequently scheduled SidekiqAlive heartbeat is normal. No dead jobs observed.

## Fresh checks

| Check | Result |
| --- | --- |
| Inbox health | PASS, `{"status":"woot"}` |
| PostgreSQL/Redis | PASS, `pg_isready` and `PONG` |
| Sidekiq | PASS, registered process |
| n8n main/worker readiness | PASS, `{"status":"ok"}` |
| Signed synthetic empty-status callback | PASS, HTTP 200 |
| Invalid signature | PASS, HTTP 401 |
| Backend | PASS, 480 examples / 0 failures |
| Focused frontend | PASS, 5 files / 15 tests |
| Changed Ruby lint | PASS, 7 files / no offenses |
| Configured Ruby audit | PASS with existing documented Devise exceptions; not a raw zero-finding claim |
| Application HIGH/CRITICAL rescan | PASS, zero findings |
| n8n HIGH/CRITICAL rescan | FAIL, 13 critical / 72 high findings |
| Full repository suites/build/low-medium inventory | NOT rerun; previous exact-artifact/baseline evidence remains in the candidate report |
| New public tunnel/live Meta/end-to-end workflow | Pending operator tunnel URL and remaining live-test prerequisites |

Backend used a fresh Git archive of the checked HEAD in a new Linux source directory and separate disposable PostgreSQL database `volitex_resume_20261014`, not the staging database. Ruby 3.4.11/rbenv initialized, Bundler 2.5.16 and `bundle exec` used. It includes provisioning, platform account/assignment/mailer regressions, Quick Menus, signatures/duplicates, ownership/handoff, encryption/deletion, providers/inbound, and synthetic campaigns. Bulk provider delivery remains mocked.

Commands: focused RSpec batch via temporary `volitex-resume-focused-20261014.sh`; `bundle exec bundle-audit check --update`; changed-file `bundle exec rubocop`; `pnpm exec vitest run app/javascript/dashboard/components-next/message/bubbles/specs app/javascript/dashboard/components-next/quickMenus/specs app/javascript/dashboard/routes/dashboard/settings/quickMenus/specs --maxWorkers=2 --minWorkers=2`; pinned Trivy 0.75.0 `image --scanners vuln --severity HIGH,CRITICAL --format json` for both immutable images; `git diff --check`.

Evidence logs: `volitex-resume-focused-20261014.log`, `volitex-focused-frontend-20261014.log`, `volitex-signature-runtime-20261014.log`, `volitex-post-resume-state.log`, `volitex-retire-old-containers.log`, `volitex-inbox-20261014-scan.log`, `volitex-n8n-20261014-scan.log`; scan JSONs in the existing temporary image-audit directory. Sensitive backup contents are excluded from these reports.

## Next gate

Start ngrok against the intended local ingress and provide its current HTTPS URL. Verify reachability and update only local `FRONTEND_URL`. Keep the global Heroku App Review callback unchanged; any test-phone callback redirect requires its scope/impact to be confirmed. Live sends still require the authorized recipient and approval for the specific bounded test. Signature verification remains enabled and the local channel app secret remains encrypted.

The n8n security gate, baseline-wide CI disposition, full authenticated ownership/idempotency workflow, live delivery and actual KVM operational acceptance remain unresolved. See [candidate evidence](production-candidate-2026-10-13.md). A localhost restart is not proof of KVM reboot recovery or production reliability.
