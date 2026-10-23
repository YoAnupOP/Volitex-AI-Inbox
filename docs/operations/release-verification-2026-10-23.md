# Volitex AI Inbox release verification — October 23, 2026

Image source: `b13c06a4694f5c7a9c73a631e064436aa624c455`. Documentation revisions are separate from image source. This record supersedes the earlier October 23 release baseline; older audit records remain historical evidence.

## Completed release gates

- [Verify non-production candidate](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39970961221): completed, success.
- [Verify migration compatibility](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39970961231): completed, success.
- [Verify campaign lifecycle](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39970961348): completed, success.
- [Run Chatwoot CE spec](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39970961293): completed, success.
- [Actual publication job](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39976372981): completed, success; all five immutable references are in the production runbook and exported kit. Anonymous manifest SHA256 verification passed for each reference.

## Changes and failed-gate remediation

- OSS Super Admin feature/limit fields and monochrome light/dark branding are restored without Enterprise code or license-check bypasses. Stored limits do not introduce new quota enforcement. New-account shipped defaults enable WhatsApp campaigns; stored installation overrides and explicit selections remain authoritative. Existing accounts are unchanged. The separate production campaign worker retains its queue/resource/network isolation.
- DOMPurify is locked to 3.4.17 for the direct and Vue plugin dependency paths, resolving the newly reported Critical/High advisories [GHSA-cg2g-xh64-v4q7](https://github.com/advisories/GHSA-cg2g-xh64-v4q7) and [GHSA-mrv2-3pqr-j5jr](https://github.com/advisories/GHSA-mrv2-3pqr-j5jr).
- TOML 4.2.0 caused three new High findings in the prior candidate gate (CVE-2026-114141, CVE-2026-114143 and CVE-2026-114144). The overlay and actual runtime resolution now use TOML 5.0.1. Tests cover CommonJS callers, normal values, null-prototype results and bounded adversarial parsing. See the [upstream security release](https://github.com/BinaryMuse/toml-node/releases/tag/v5.0.1).
- Legacy round-robin tests explicitly disable assignment_v2 because they stub the legacy Redis path. No production assignment behavior was changed to satisfy a test. Full CE passes all 20 jobs. The postcss-import direct dependency declaration uses its existing locked version.
- Local verification includes the requested account provisioning suite, model/Compose regressions, all 108 conversation examples, actual-runtime n8n checks (10/10), frontend sanitizer/theme regressions and rendered browser checks in light/dark mode. CI additionally validates built-image boot, guarded replies, upgrade/restore and interrupted-reply recovery. No real campaign recipients were contacted by these tests.

## WhatsApp media and retry follow-up

The local preview had a Compose-level localhost FRONTEND_URL override despite an ngrok URL in its env file. The override was removed, the current HTTPS URL applied to the web/workers and the Meta WhatsApp callback updated with existing verification settings. External media fetching returned the actual PNG bytes, and a controlled outgoing JPEG obtained a read-status webhook. These are local integration checks, not production acceptance. No secret rotation was needed.

The follow-up also found that an asynchronously failed message retained source_id, causing the retry job to skip it as already originating from the provider. The retry action now locks and claims only failed messages, clears the old provider identity and queues one new attempt. Repeated claims and retries of sent/delivered messages are rejected. The focused controller/provider suites passed 56 examples and RuboCop; all four exact-source release gates and actual publication above passed for this fix. The runbook includes effective environment precedence, container recreation, public media URL and actual delivery acceptance.

## Security evidence and limits

Publication rescanned all five images. There are zero unresolved Critical/High runtime findings within the restricted private operator-managed HTTP/JSON profile. Raw findings remain intact; no alerts or audit checks were suppressed. The n8n braces High and stream-json Medium are resolved by the existing independently verified source backports. Remaining Medium/Low findings, including ip-address and nodemailer, are retained in the raw publication evidence and maintenance documentation.

Exact raw publication counts:

```json
{
  "inbox": {
    "MEDIUM": 2,
    "LOW": 1
  },
  "n8n": {
    "MEDIUM": 10,
    "LOW": 1,
    "HIGH": 1
  },
  "n8n-postgres": {},
  "n8n-valkey": {},
  "inbox-postgres": {}
}
```

The complete checksummed kit includes raw scans, source markers, verified backports, registry references and exact-source acceptance evidence. Do not substitute mutable tags or the older kit. MCP modules remain disabled; enabling additional nodes or modules requires separate review and acceptance.

## Deployment boundary

No production KVM is deployed by this publication. Actual private networking/TLS, off-host backup restore, reboot, alert delivery, measured capacity, Meta/media and each client's workflow acceptance remain required. Keep campaigns disabled on unaccepted accounts. Use the [production runbook](first-client-production-runbook.md) and [OSS account feature guide](super-admin-oss-features.md).

## Release alignment and operations acceptance

This source also includes the later Super Admin settings/background/text/icon fix and the SMTP n8n/campaign failure monitors, guarded Sheets recovery and systemd units. All 16 operator-tool regression tests are part of the candidate contract gate. Local acceptance records cover real WhatsApp/Google Sheets and one-recipient marketing delivery plus isolated recovery; see the evidence directory. Mailbox receipts are founder-confirmed. Monitor delivery is at-least-once, unknown campaigns are never automatically resent, and no recovery scheduler is enabled. KVM monitoring, restore/reboot/load and actual client workflow acceptance remain pending.

The [fresh dependency inventory](dependency-reconciliation-2026-10-23.md) preserves every open alert disposition without dismissals. Its production npm audit and exact-source candidate/publication scans are distinct from the repository badge.
