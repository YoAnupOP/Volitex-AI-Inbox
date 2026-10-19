# Actual n8n capability inventory — 2026-10-19

**Current follow-up:** [restricted profile selection and remaining release gates](n8n-restricted-profile-assessment-2026-10-19.md). Earlier unset-image/failure/architecture statements below are historical assessment stages, not the current selected package. No existing staging or production deployment was changed.

## Scope and conclusion

Inspected repository deployment workflows/custom nodes, AgentBot listener/transport, ownership/message API, current security reports and read-only staging workflow metadata. **No approved first-client business/AI workflow is present in this repository or the inspected staging database.** The single staging workflow is a deterministic phrase responder. It is evidence for the integration contract, not a production capability specification.

The founder-confirmed offer is managed WhatsApp/Instagram appointment booking with calendar/CRM integration, tenant boundaries and human takeover. Calendar/CRM providers are chosen per client; no provider-specific API contract, LLM provider/prompt, approved tools, OAuth credentials, production routing, input formats or node allowlist is approved by that service-level choice alone. None was invented or disabled to manufacture security clearance. Inbox continues to own campaigns and provider delivery; n8n is not a substitute sender.

## Observed capabilities versus intended service

| Capability/input | Repository/runtime evidence | Security-relevant disposition |
|---|---|---|
| Meta inbound WhatsApp/Instagram | Existing Inbox controllers/services own callback verification and conversation creation | User text/media remain untrusted; Meta signature proves provenance, not parser safety |
| Inbox→n8n events | AgentBotListener emits conversation/message events; Webhooks::Trigger serializes JSON and signs fixed bytes | New private exception requires operator-bound bot/account/URL/IP and matching secret; no arbitrary tenant destination |
| n8n inbound route | One example Webhook node, rawBody enabled | HMAC validation occurs after global n8n middleware; networking and parser/middleware disposition still required |
| Validation/reply node | CUSTOM.volitexReply verifies signature/timestamp, event/account/inbox/contact and owner/window | No credential/origin selected from payload; fixed phrase and fixed reply; not a generic agent or tool executor |
| Expressions | RespondToWebhook evaluates the committed `$json.verification` expression | No repository code promotes inbound message text into an expression/template/AST; no claim all n8n expressions are safe |
| Outbound request | Custom node uses HTTP helper with operator credential URL, bot API token and fixed account/conversation endpoints | Hostname allowance is exact; generated automation_delivery_id deduplicates Inbox reply creation |
| Actual staging nodes | Read-only SQL: one workflow; distinct types CUSTOM.volitexReply, n8n-nodes-base.webhook, n8n-nodes-base.respondToWebhook | No client-specific AI/Git/email/parser graph demonstrated |
| Available node capabilities | Staging NODES_INCLUDE/EXCLUDE unset; vendor defaults apply; image contains Git, SSH, EmailSend and many other nodes | Installed does not mean reached by smoke graph; neither does smoke absence mean platform-wide denial |
| Git/core source-control | Builtin Git node imports simple-git; enterprise source-control/promotions also call it | Approval/license/module gates not proved closed globally; command/config/repository inputs need explicit policy |
| SSH | Builtin Ssh uses node-ssh JavaScript; Git can invoke native SSH | Do not attribute native OpenSSH CVEs merely to JS SSH node; native transport remains distinct |
| Email | Core mailer and EmailSend nodes use Nodemailer; SMTP configuration exists | Tested core raw-option boundary is safe for that call; address-parser and node-specific inputs not globally cleared |
| Handlebars | Core file-template mailer, engine helpers, OAuth/forms/SAML rendering callers | File→UTF-8 string excludes AST at that compiler; no global template capability approval |
| TOML/braces/XML/ZIP/native formats | Not invoked by the committed custom JSON-only smoke graph; bundled parsers/other nodes exist | Actual permitted formats and downstream tools are unspecified; unresolved inventory retained |
| LLM/AI/business orchestration | No production model node/prompt/tool policy or client business workflow found in inspected evidence | Missing functional/capability specification, not permission to allow every node |
| Campaign delivery | Existing Inbox campaign ledger/provider services own consent, pacing, unknown outcomes and reconciliation | Campaign feature stays gated; no n8n campaign delivery engine added |
| Direct external n8n trigger/OAuth | None needed by inspected custom credential or graph; onboarding portal is separate | Internal-only remains recommended target; future external integration needs a separate explicit route/callback decision |

## What is required to close the capability gap

### Founder-confirmed service scope

On 2026-10-19 the founder selected appointment booking with calendar/CRM integration and confirmed that providers will be selected per client. This specifies the initial managed-service offer, not approval of any provider, n8n node, credential scope or production workflow. The observed fixed-reply graph remains integration evidence only. Provider-specific workflows are configured and accepted during client onboarding; building every calendar/CRM connector before the first sale is not a platform readiness requirement.

The founder subsequently confirmed real estate as the initial sector, including FAQs, lead qualification, booking and human handoff. Pricing and commercial decisions are outside the technical readiness gate. Human takeover already exists in Inbox; accept its server-side ownership/reply enforcement under replay and worker interruption, rather than adding another UI toggle.

Before the first sale, verify the reusable Inbox/n8n authentication, tenant isolation, reply idempotency, ownership handoff, supported runtime/security controls and deployment/recovery package. Before activating a client's booking automation, record and pass the following provider-specific acceptance profile:

| Area | Required record and acceptance |
|---|---|
| Provider and ownership | Calendar/CRM product and API version, client-owned account/calendar/pipeline, tenant-bound credential references and minimal scopes; never credential values in this record |
| Booking policy | Client timezone, working hours, duration/buffers, required contact fields, explicit confirmation rule and supported cancellation/rescheduling behavior |
| Availability and concurrency | Recheck the requested slot before creation and exercise two concurrent requests for the same slot; document the provider's actual conflict/hold guarantees and the selected handling when atomic reservation is unavailable |
| Stable identity and retry | Persist one booking operation identity across webhook/API retries; use provider idempotency or lookup/reconciliation where supported. After an ambiguous create response, reconcile or hand off instead of blindly creating another event |
| Calendar and CRM separation | Confirm a booking only after calendar success is known. A failed CRM update must retain the confirmed calendar reference and retry/upsert the CRM record without creating the calendar event again |
| Tenant and account boundaries | Reject foreign account/calendar/CRM IDs; never choose credentials or API origins from inbound customer text. Preserve the dedicated AgentBot and fixed account binding |
| Human ownership | A human takeover blocks subsequent automated Inbox replies; define who follows up on uncertain booking outcomes and CRM failures. A takeover does not automatically cancel an external appointment |
| Provider failure and recovery | Exercise rate limits, expired/revoked credentials, timeout before and after provider acceptance, worker interruption, duplicate deliveries and restore/restart with synthetic data. Verify the actual reconciliation and operator alert path |
| Business workflow and security | Version the selected nodes, fixed outbound origins, model/tools if used, permitted input formats, sensitive-data retention and error workflow. Reassess material dependency callers for this profile before enabling additional capabilities |
| Client acceptance | Record synthetic/test-account results and the separately authorized client-channel smoke test; obtain approval of the booking policy and customer-facing confirmations before live activation |

Before declaring all material findings non-applicable, approve and version a concrete initial workflow/capability manifest: node types/versions, core modules, credentials/owners, fixed outbound destinations, input formats/size limits, model/tool permissions, expression/template boundaries and error/handoff behavior. Use supported NODES_INCLUDE/EXCLUDE if it matches those actual requirements, and regression-test execution rejection of disallowed nodes; this does not disable vulnerable core services automatically.

This is a genuine missing engineering input. The inspected staged database does not contain an undiscovered production workflow that can be tested instead. Do not silently convert its phrase responder into a commercial AI workflow or assert Git/mail/parser prerequisites are unreachable merely because it omits them.

## Evidence boundary

Staging metadata query read only workflow count and distinct node types; no credential, workflow-parameter or customer-data export. Existing2.43.4 services were not changed. Synthetic acceptance uses isolated2.43.4→2.43.7 databases and generated scoped credentials, not staging data. Candidate results are recorded separately; they establish integration/recovery behavior only for the tested contract.

## Versioned runtime policy follow-up

The deployment source now loads `deployment/n8n/runtime-policy.env` into both main and worker. It limits the baseline to HTTP/JSON operations, control flow, schedules, errors and the custom authenticated Inbox reply node. The 18 explicit types include the date/time and HTTP tool wrappers generated by n8n. Git, SSH, shell execution, Code, mail-sending, filesystem, XML and archive nodes cannot load. Source-control, promotions and community-package modules are excluded through the installed module registry's supported configuration. Existing staging has not been changed.

The deployment source also selects private n8n access: only the ordinary Inbox worker and n8n main share an externally provisioned internal bridge; main has a required reserved IP, no host port, and `traefik.enable=false`. Application and n8n database networks remain separate. The editor uses the operator's localhost SSH forward with secure cookies retained. The acceptance harness now uses separate app, n8n and automation bridges and tests that Rails cannot connect to the private main address. Actual Coolify router/network inspection and operator browser/tunnel recovery still require server acceptance.

Use HTTP APIs for the initial provider integrations. Adding a provider-specific or AI node requires a versioned policy change and the corresponding credential/input/recovery checks; never set an empty include list to enable arbitrary nodes. Node restrictions do not disable core email, rendering or parsing services and do not patch their dependencies.

`script/production/verify_n8n_policy.cjs` exercises the real installed node registry, including execution-time type resolution. It checks every loaded type against the list, loads all 18 allowed types, rejects blocked types and their synthetic tool aliases, and verifies the three disabled modules are ineligible. The candidate CI workflow runs this probe in a network-disabled container. Production Compose rendering confirmed the same policy on both processes.

The latest official stable checked was [2.43.8](https://github.com/n8n-io/n8n/releases/tag/n8n%402.43.8), at `n8nio/n8n@sha256:a18edcf018198b33b5488fb47ededafe11e0b10d28f65b9535b7c447c9ce3b2c`. Its release note describes an expression-span default change, not remediation of all outstanding advisories. The loader probe passed on this exact image. An earlier probe exposed automatically generated tool aliases; the final policy explicitly lists and verifies those two aliases through the actual execution resolver.

Trivy 0.75.0 scanned 2.43.7 and 2.43.8 using the same downloaded database, with updates disabled between scans and no finding suppression. Both reported **11 critical, 35 high, 93 medium, 27 low and 1 unknown**. This change does not approve 2.43.8 for production; `N8N_IMAGE` remains unset pending remaining material caller/security disposition and deployment-profile acceptance. The distroless image contains no `apk`; no unsupported transitive-package replacement or package-manager bootstrap was attempted.

The first isolated 2.43.4→2.43.8 upgrade/recovery run with this node policy passed, using the previously published Inbox plus read-only transport source overlays: authenticated round trips, invalid HMAC/foreign-tenant rejection, replay, worker interruption after the API commit, queued work recovery, human takeover and restored prior-state credentials/workflow. Exactly five fake-provider calls matched five intended replies. The interrupted run recorded one crashed execution and 33 successes; the crashed execution was not relabeled successful. This establishes that tested overlay contract, not a final application artifact.

The acceptance harness now requires `--app-image` and `--source-sha`, checks the embedded source marker, and mounts no application source over the supplied image. Run it against the actual built release before accepting that artifact:

```sh
python3 script/production/verify_n8n_acceptance.py --app-image <tested-application-image> --source-sha <full-source-sha>
```

Node monitor/reply checks passed 16/16 on Linux; the two cleanup-ownership harness checks passed. The first Windows monitor attempt failed because its Bash invocation could not resolve `cygpath`; the Linux-target rerun passed without modifying production monitor behavior. These results do not clear existing full-suite/lint debt or actual KVM acceptance.


## General production reply operations

The custom node now offers `Authorize Automation` and `Send Reply` alongside the existing staging-only operations. Authorization verifies the raw signed body, tenant/inbox/contact, current conversation ownership and service window. Only its first output may lead to AI/provider actions; its second output handles rejected/ignored events. Downstream expressions must use `verifiedEvent`, not an incoming parsed body. Preserve the original raw binary `data` and signature headers through provider/AI nodes, merging them back before Send Reply when a node replaces its input.

Send Reply requires configured text, checks live ownership again, and uses the incoming message identity as its idempotency key. Failed authorization reads fail the execution so they are visible and eligible for bounded recovery. Invalid signatures and human ownership do not proceed to customer actions. Reauthorize immediately before calendar/CRM writes as well, and give those writes provider-supported idempotency keys. A human takeover cannot undo an external booking already committed. These reply guarantees do not establish booking/provider idempotency until a specific integration is selected and accepted.

The monitor now requires both database URLs and both Redis URLs. It alerts on recent n8n `error`/`crashed` executions, including executions interrupted after a committed external effect. Reconcile effects before replay; never bulk-retry failed booking executions blindly.

Intermediate actual-image acceptance passed source-marker, isolated boot, bridge membership, blocked Rails-to-n8n access, authenticated old/new round trips, rejected HMAC/foreign tenant, interrupted-reply duplicate safety, queued recovery, human takeover and the crashed-execution monitor query. The run then exposed a harness variable collision at the general-workflow import; it is not recorded as an overall pass. Remote candidate boot and package audit passed, but its acceptance step failed importing fixtures. The harness now mounts a readable synthetic fixture child beneath a host-private temporary directory, supporting CI/container UID differences, and separates the n8n user ID from Inbox automation ownership. A complete rerun remains required.

Focused Linux monitor/reply checks: 24 passed. Exact 2.43.8 node/module/DTO policy probe: passed, 18 allowed types. These checks do not approve the whole release or change `N8N_IMAGE` from its pending state.
