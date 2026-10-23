# Volitex AI Inbox dependency reconciliation — October 23, 2026

## Verified release result

Source `b13c06a4694f5c7a9c73a631e064436aa624c455` passed candidate, migration, campaign and full CE gates (20/20 CE jobs). [Actual publication 39976372981](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39976372981) succeeded. All five anonymously fetched registry manifest hashes match the published immutable digests. No new application dependency change was required by this reconciliation.

| Image | Fresh raw findings | Unresolved Critical/High in the restricted profile |
| --- | --- | ---: |
| Inbox | 2 Medium, 1 Low | 0 |
| n8n | 1 High, 10 Medium, 1 Low | 0; verified backports retained in evidence |
| n8n PostgreSQL | 0 | 0 |
| Valkey | 0 | 0 |
| Inbox PostgreSQL/pgvector | 0 | 0 |

## Scope and evidence

This review reconciles the current GitHub alerts with source `b13c06a4694f5c7a9c73a631e064436aa624c455`, the maintained dependency overlay and immutable release images. The [complete inventory](dependency-reconciliation-2026-10-23.csv) records each alert, package, manifest, advisory, affected/patched ranges, current versions and disposition. The [evidence record](evidence/dependency-reconciliation-2026-10-23.json) identifies the private input hashes, publication and registry checks. No alerts were dismissed and no audit suppression or unrelated upgrades were introduced.

The fresh API snapshot contains **224 open alerts: 11 Critical, 105 High, 93 Medium and 15 Low**. This supersedes the earlier repository inventory; older reports remain historical evidence. Counts and advisory classifications can change independently of a source commit.

| Manifest | Alerts | Exposure |
| --- | ---: | --- |
| `deployment/n8n/npm-candidate/package-lock.json` | 156 | Rejected assessment recipe; excluded from maintained build and deployment kit |
| `pnpm-lock.yaml` | 45 | Inbox browser/build/test dependency graph |
| `tests/playwright/pnpm-lock.yaml` | 17 | Separate browser test project |
| `tests/playwright/package.json` | 1 | Separate browser test declaration |
| `package.json` | 1 | Root development dependency declaration |
| `deployment/n8n/hardened/package-lock.json` | 2 | Maintained n8n overlay, Medium findings below |
| `Gemfile.lock` | 2 | Devise Medium findings with existing mitigations |

## Critical and High reconciliation

Nine Critical alerts belong to the rejected assessment, and two concern the tinypool test tool. Of the 105 High alerts, 67 belong to the rejected assessment, 23 to the Inbox browser/build/test graph and 15 to the separate Playwright project. Development-tool risks remain open; do not run untrusted tests/configuration with production credentials or expose development servers publicly.

All npm package/ecosystem branches from each current advisory were compared against the actual maintained n8n physical package versions. Comma-separated comparators were normalized before semver evaluation; unsupported ranges fail the comparison. **Zero Critical/High advisory ranges from this snapshot match installed maintained n8n packages.** This version comparison is separate from scanning every image and does not declare the rejected recipe safe.

The fresh `pnpm audit --prod` result has **zero findings at every severity**. This assesses the production dependency graph, including dependencies compiled into browser assets; removal of `node_modules` alone would not establish browser safety. Development/test graph findings are retained in the inventory.

The new TOML High advisories (`GHSA-9qmh-m7c6-f92p`, `GHSA-9j65-hcg3-gc64`, `GHSA-4qx8-w7c3-pj3p`) affect versions through 5.0.0. Maintained runtime TOML is already 5.0.1, so no additional upgrade is needed. See the [upstream advisory](https://github.com/advisories/GHSA-4qx8-w7c3-pj3p). DOMPurify 3.4.17 and earlier targeted dependency/security fixes are already present; this review does not reimplement them.

The raw n8n braces High and stream-json Medium findings remain visible. Their existing source backports require independent source/hash and behavioral verification in candidate and publication checks. No scanner-ignore rule replaces that verification. The [release verification](release-verification-2026-10-23.md) records the actual publication scans and exact-source gates; the [runbook](first-client-production-runbook.md#verified-release-and-deployment-kit) is authoritative for approved immutable pins.

## Remaining findings and restrictions

- Nodemailer 10.0.9 matches Medium `GHSA-39m8-27wv-hr27`; 10.0.10 is the reported patch. ip-address 10.7.1 matches Medium `GHSA-rxp7-6hxx-x8q5`; 10.7.4 is the reported patch. These remain maintenance findings, not hidden exceptions.
- Devise retains the existing unconfirmed-email dirty-tracking mitigation and disabled Timeoutable trigger, with regression coverage and documented audit exceptions. No authentication overhaul was introduced.
- Development/test findings include tinypool, launch-editor, Vitest/mocker and the separate Playwright graph. Their individual ranges/dispositions remain in the CSV. Compatible toolchain remediation is separate maintenance work, not evidence of a production runtime Critical finding.
- n8n remains a private, trusted-operator HTTP/JSON deployment. MCP backend modules and excluded nodes stay disabled. Opening public workflow authoring or enabling additional integrations invalidates this scope and requires a fresh review.
- Lower-severity image findings remain in raw scan evidence. Recheck current advisories and registry availability immediately before server deployment; today's checks are not a permanent vulnerability clearance.

## Release and deployment boundary

Release alignment includes the latest Super Admin theme fix, workflow/campaign failure email monitors, guarded Sheets recovery, their systemd units and acceptance records. A green workflow title alone is insufficient: require all four exact-source gates and a successful actual publication job, then verify all five immutable registry manifests and exported Compose configurations before promoting the kit pointer.

Local acceptance covers live WhatsApp/Sheets save/update, AI OFF/human handoff/ON resume, duplicate protection, outgoing media and a one-recipient approved marketing campaign; SMTP mailbox receipts and isolated recovery acceptance are recorded separately. It does not establish KVM capacity, multiple-client bulk throughput or acceptance of calendar/CRM booking workflows.

KVM networking/TLS, private service bindings, fresh protected secrets, off-server backups and a real restore, reboot/queue recovery, persistent monitoring and independent alert escalation, measured capacity and each client's integration acceptance remain deployment gates. Campaigns remain gated for unaccepted clients. No production deployment, credential change, destructive recovery or spending is part of this review.
