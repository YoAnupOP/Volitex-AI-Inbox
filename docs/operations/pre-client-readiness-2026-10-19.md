# Pre-client readiness evidence — 2026-10-19

Status: release gates still running; no deployment approval or 100% reliability claim.

## Changes implemented

- Private Inbox-worker → n8n-main transport with account/bot/URL/IP-bound configuration; no global SSRF relaxation.
- Separate app, n8n and automation networks; private main, no public n8n router or host port.
- Versioned 18-type node policy and disabled Git/community modules, checked through the actual execution registry.
- General authorize/send-reply operations for normal customer text, signed raw event context, separate rejection output, live ownership recheck and stable reply idempotency identity.
- Required DB/Redis monitor configuration and recent n8n error/crashed execution alerts.
- Runtime `libexpat` upgrade from 2.8.5-r0 to patched 2.9.0-r0.

## Completed evidence

Application source `5c94dde1158a541c05ffeacbac65401af67b120d`: full built-image acceptance PASS, no application source overlays. [Safe result](evidence/n8n-acceptance-5c94dde115-2026-10-19.json). Includes 2.43.4→2.43.8 upgrade, signed tenant-scoped Inbox replies, invalid signature/foreign-tenant rejection, interruption after the API commit, one provider effect under replay, queue recovery, human takeover, ordinary customer text/configured reply, crashed-execution query and restoration of prior credentials/workflow. Exactly six intended fake-provider effects.

Application source `24be9585e9a0b6366dab4db6b938b19191859a79` adds the runtime OS fix. Its production build and isolated migration/web/worker/connectivity/restart/graceful-stop/storage/PostgreSQL-restore check passed. Local image ID: `sha256:1b93779706c8914b036693ee59f444e0d64273746adda455072ed140b9a63a61`. This is a local image identity, not a registry pull digest.

Final local application scan: **0 critical, 0 high, 2 medium, 1 low**, no suppression. Trivy 0.75.0, vulnerability database updates disabled between comparison scans. Before the OS fix: one high and three medium plus one low. Final JSON SHA256 `bb0c27d2514c49b4e7acf41de085e27dfbe29f0df10ddf77a2a61f155245f2fe`. Remaining findings retain their earlier dispositions: the email-reconfirmation race fix is backported in User; Timeoutable is disabled on User/SuperAdmin; bundled application execution selects patched JSON 2.21.2 (verified in this exact image), while the old default gem is still present. Existing user_email_reconfirmation_security specs cover the backport/module boundary. These rows remain visible; no scanner suppression or blanket dependency-security clearance.

Focused monitor/reply checks 24/24; cleanup ownership checks 2/2; exact n8n 2.43.8 policy probe PASS with 18 allowed types. n8n scan still contains 11 critical/35 high; all 46 identities are represented in the inventory. See [restricted profile assessment](n8n-restricted-profile-assessment-2026-10-19.md). This is separate from the application image scan.

## Outstanding release gates

- Full acceptance on the OS-patched source and exact-source CI completion.
- Final restricted n8n profile disposition and deployment pin; `N8N_IMAGE` remains unset.
- Publish and verify a transport-capable application registry artifact before selecting it in the runbook.
- Actual server acceptance: router/network inspection, SSH tunnel/browser login, independent alert delivery, off-host backup restore, resource/load baseline and client-provider credentials/idempotency. No VPS has been purchased or changed.

The earlier published application at source 66aa7305bf remains historical evidence and lacks the newer private transport. Existing staging was not migrated. No real customer/Meta messages were sent. Full-suite/lint baseline failures described in earlier reports are not relabeled green.


## Repeat-run failure retained

The first full run on OS-patched source 24be9585e9 passed the earlier upgrade/interruption/queue/handoff/monitor checks but timed out waiting for the ordinary customer reply. Inspection found the published database graph had authorize/sendReply while the execution used the old staging phrase guard. This is not relabeled PASS. The harness/update runbook now pause Inbox delivery, stop n8n writers, import/publish through a one-shot CLI process, verify the active-version graph, recreate main/worker and await both readiness checks before resuming delivery. The corrected full run remains pending.
