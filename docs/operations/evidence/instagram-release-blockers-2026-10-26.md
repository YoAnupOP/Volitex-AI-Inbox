# Volitex AI Inbox Instagram release verification — October 26, 2026

The first Instagram lifecycle candidate, `e7b3126fb93528ee5185a7cf916810415d1bbaf2`, is **not an approved release**. Do not update a deployment pin or the exported release-kit pointer to this candidate.

## Gate findings

- [Full CE run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/40342599785): dependency security rejected Crass 1.0.7 ([GHSA-pq4g-8rxf-4g29](https://github.com/rgrove/crass/security/advisories/GHSA-pq4g-8rxf-4g29)). The follow-up changes only Crass to 1.0.8 and adds the tokenizer boundary regression. Two builder shards also exposed arrival-order changes; the follow-up preserves message `created_at` and stores normalized provider event time separately for reply-window enforcement.
- [Migration run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/40342599297): migrations and compatibility checks reached the dependency-audit step, which rejected the same Crass advisory. This does not establish a passing overall gate.
- [Campaign run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/40342599287): passed on that source.
- [Candidate run](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/40342599255): n8n contract passed; n8n runtime security failed. Its `n8n-image-vulnerabilities` artifact contains eight unresolved High findings across five package names. These are physical package occurrences, not eight distinct advisories.

## Separate n8n release blockers

| Package versions found | Physical occurrences | Advisory | Scanner's fixed version |
| --- | ---: | --- | --- |
| `@azure/msal-node` 5.1.5, 5.6.0 | 2 | CVE-2026-109461 / GHSA-xcx6-jx8p-x3h5 | 7.1.0 |
| `body-parser` 2.3.0 | 2 | CVE-2026-111181 / GHSA-27r3-jxmh-p828 | 2.4.0 on the installed major |
| `multer` 2.4.0 | 1 | CVE-2026-113872 | 2.5.0 |
| `undici` 6.29.0, 7.29.1 | 2 | CVE-2026-109869 / GHSA-xjj6-f33q-929c | 6.29.1 and 7.30.1 respectively |
| `zod` 3.25.76 | 1 | CVE-2023-54404 / GHSA-mrhx-c7xc-m3w5 | 4.6.6 |

No finding has been dismissed or suppressed. The maintained n8n overlay was not changed as part of the Instagram implementation. Remediation needs its own compatibility verification: preserve each Undici major, check MSAL's public API compatibility, and avoid substituting Zod 4 for Zod 3 without validating callers. Zod's upstream constrained-container fix is documented in [PR 6652](https://github.com/colinhacks/zod/pull/6652); it does not make arbitrary unbounded schemas resource-bounded.

Rerun all four gates for the final application source. The n8n runtime gate remains a deployment-kit publication blocker until independently verified remediation passes. Older image/kit pins have not acquired fresh security clearance merely because they were published previously. Actual Meta consent, subscribed webhook delivery, reconnect, and provider-side message acceptance remain separate live acceptance checks; local HTTP stubs cannot prove them.
