# n8n exposure architecture decision — 2026-10-19

**Current follow-up:** [restricted profile selection and remaining release gates](n8n-restricted-profile-assessment-2026-10-19.md). Earlier unset-image/failure/architecture statements below are historical assessment stages, not the current selected package. No existing staging or production deployment was changed.

Follow-up: the [private AgentBot transport](agentbot-private-transport-2026-10-19.md) is now implemented/tested in an isolated source branch. It is **not in the unchanged published Inbox image** and has not been adopted in staging/production. The analysis below records the original decision baseline; source compatibility evidence does not itself clear n8n advisories or authorize deployment.

## Recommendation: Option A, internal-only n8n — proposed, not applied

The repository's current verified functional contract needs **no public n8n endpoint**. Recommend private Inbox-worker-to-n8n-main delivery, private n8n editor access through an operator SSH tunnel, and n8n-to-Inbox API via the existing authenticated public Inbox HTTPS origin. Keep main/worker, PostgreSQL and Valkey roles unchanged. This recommendation has a concrete compatibility gate below; the frozen Inbox image cannot simply be pointed at a Docker hostname today.

No Compose/environment/staging network was changed. This is not an architecture adoption or deployment authorization. Public n8n hostname is not required by queue mode, schedules, outbound HTTP or this custom credential. Do not invent a requirement for n8n.volitexai.tech. A later integration needing OAuth callback or external trigger must undergo its own route/callback assessment; Inbox is not a generic third-party webhook relay.

## Verified functional and exposure facts

- `deployment/n8n/inbox-reply.workflow.json`: Webhook → CUSTOM.volitexReply validation → RespondToWebhook → CUSTOM.volitexReply reply. These are the only three node types in that example. It remains a fixed staging phrase responder, not the client's business automation.
- `lib/webhooks/trigger.rb`: Inbox serializes JSON, POSTs with fixed content-type, timestamp, delivery ID and HMAC through SafeFetch. n8n URL originates from configured AgentBot, not customer content.
- `deployment/n8n/custom/VolitexReply.node.js`: credentials fix base URL/account/inbox/bot and token. Incoming content cannot select another credential or API origin; authoritative conversation/owner/window are checked before an idempotent reply.
- No configured direct Meta→n8n trigger, n8n OAuth credential or third-party public webhook is needed by that example. Separate connect portal keeps its own existing OAuth/Embedded Signup; do not move it into n8n.
- Current production example describes public automation.volitexai.tech plus Traefik identity middleware. Main has container expose5678 but no host ports. Worker/PG/Valkey have no public mappings. Those declarations are not actual KVM exposure proof.
- Read-only local inspection found main/worker on **2.43.4**, `n8nio/n8n@sha256:c34ee9107a42b837e25cec0c8a927ab90a45b776aa2ccbf15e5b9cda466fad2c`, not the intended assessed2.43.5 or candidate2.43.7. Main binds127.0.0.1:5679; its DB/Valkey are healthy. No full laptop tunnel/firewall exposure audit is claimed. Original container state was not changed.
- Local selected flags: queue mode, public API disabled, community packages disabled, proxy hops1; NODES_INCLUDE and NODES_EXCLUDE unset. This means vendor defaults, **not a three-node allowlist**. No decrypted credentials or workflow database were read/exported.

## A versus B

| Requirement | A: internal-only | B: public hostname behind Traefik |
|---|---|---|
| Existing Inbox event and API reply | Fits business flow; currently blocked by Inbox SSRF policy until narrow exception exists | Fits existing public-HTTPS webhook transport and previous proxy design |
| External workflow trigger | None required by inspected example; would need separate decision if added | Expose only demonstrated required routes, not wildcard editor/API by default |
| Queue/main/worker/persistence | Same architecture; no public hostname required | Same architecture; hostname adds no queue/recovery property |
| Authentication/tenant correctness | HMAC, timestamps, account-scoped bot and reply key remain mandatory | Same; HTTPS/auth do not protect middleware executing before auth |
| Administration | SSH-forwarded loopback/private origin; browser cookies/origin/TLS and recovery must be tested | Convenient HTTPS editor, but requires verified restrictions against unrelated internet clients |
| Attack surface | Removes direct internet request path only if network/no-bypass is real; still consumes hostile customer content and outbound responses | Adds direct parser/middleware exposure plus route/DNS/TLS/guard operations |
| Monitoring/recovery | SSH-independent external host/Inbox checks; private workflow/worker probes and operator alerts | Same queue/worker probes plus public n8n ingress/TLS alerts |
| Solo-operator complexity | SSH already required for host; fewer public routes/certificates. Adds a narrow transport change and tunnel acceptance | Current configuration closer to deployable; more ingress rules/bypass/guard failure modes |

**Why A wins for the documented requirements:** it avoids a public service with no demonstrated external caller. This is not a dependency patch or an assertion internal inputs are safe. B remains a technically feasible alternative if future functional requirements justify external trigger routes, or if the scoped Inbox transport change is not approved; it is not automatically unsafe when its controls are verified.

## Hard compatibility gate: SafeFetch

`SafeFetch::Fetcher#perform_request` uses ssrf_filter unless `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` is true. `SafeFetch.allow_private_network?` is a global boolean; no per-AgentBot hostname exception exists. In the exact published Inbox image, a network-disabled Ruby probe calling ssrf_filter against127.0.0.1 raises `SsrfFilter::PrivateIPAddress`. Existing `spec/lib/safe_fetch_spec.rb` also covers private IP/DNS rejection; `spec/lib/webhooks/trigger_spec.rb` covers blocked private webhook failure.

Therefore **A is not deployable with today's frozen Inbox configuration as-is**. Do not enable the global override: it would widen media/download and unrelated SafeFetch reachability as well. Do not fake public DNS to bypass the safety check.

Minimum supported implementation proposal (NOT implemented here): a dedicated AgentBot webhook-only trusted destination contract, configured by operator, matching scheme/host/port and webhook path; keep redirects disallowed or revalidate every hop, preserve DNS/address pinning and exclude metadata/other destinations; require matching signed AgentBot delivery; ordinary account webhooks/media remain on default SSRF policy. Validate it with real Docker DNS/private delivery, foreign-host/redirect/rebinding/userinfo/path negatives and all existing SafeFetch tests. It would require a separately reviewed source revision and image publication authorization. The current published image remains unchanged and valid for its original public transport.

Private n8n should have no Coolify public domain/router and no all-interface host port. A loopback-only administrative listener may be reached through SSH local forwarding; test the exact browser origin and secure-cookie behavior before choosing URL/TLS settings. Do not blindly disable secure cookies or expose the editor to resolve tunnel trouble. No certificate/hostname/private-access mechanism was configured here. Keep n8n-to-Inbox HTTPS at its fixed trusted public origin unless an independently tested private API path is needed.

## Security effect of the architecture

A removes direct unauthenticated internet→n8n paths, not authenticated/untrusted-content parsing, workflow authoring, imports, credential callbacks or outbound hostile-service responses. Only Inbox workers and administrative access should reach main; do not attach every app/tenant service to a flat trusted network. A compromised permitted service remains a trust-boundary risk. Retain HMAC and exact credential/context validation even internally.

Compression1.8.1 is still vulnerable internally if reached with the relevant negotiation/disconnect behavior. Do not treat private transport as its patch or remove the verified guard from existing configuration. Candidate2.43.7 has compression1.8.2, but is not approved overall. Architecture adoption must explicitly choose a patched approved artifact or verify an equivalent narrow guard on its actual private request path.

## Finite acceptance gates

### Before KVM

1. Approve the exposure recommendation and actual first-client capability inventory (nodes/modules, credentials, input sources, OAuth and outbound integrations). The staging phrase responder is not that inventory.
2. For A, review/test the scoped AgentBot transport exception without the global private override. No production image replacement is authorized here.
3. Close remaining material dependency callers using the companion security inventory: supported patches or demonstrated prerequisite exclusions for those actual capabilities. A node allowlist is an upstream-supported option to test, not an applied control or substitute for core mailer/import/HTTP route review.
4. For any adopted candidate, clone a disposable prior-schema DB with synthetic credentials, run authenticated Inbox reply, upgrade/restore rollback and crash-during-side-effect recovery. Prior queue probe is not those tests.
5. Prove private Docker delivery and administrative tunnel/origin behavior in an isolated environment; public DNS/host purchase is not required for these checks.

### On KVM, after separate deployment authorization

Verify actual private network membership, no public n8n route/port or bypass, permitted service connectivity, admin tunnel recovery, fixed Inbox HTTPS destination, migration/key restoration, durable queue recovery, reboot, external alerts and authorized channel/tenant/handoff acceptance. For B instead, verify every generated forwarding router and required identity control, explicit route restrictions, TLS and no direct ports. No KVM gate passed merely because Compose has no ports stanza.

## Decision

**Architecture recommendation: A. Implementation/adoption: pending scoped transport and access verification. Security release verdict: FAIL** for the currently unrestricted capabilities and incomplete material reachability evidence. No public n8n hostname is required by the inspected contract; no unsupported dependency change or new paid service is proposed. See [caller-scoped security closure](n8n-architecture-security-closure-2026-10-19.md).
