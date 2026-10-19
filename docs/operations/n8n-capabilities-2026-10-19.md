# Actual n8n capability inventory — 2026-10-19

## Scope and conclusion

Inspected repository deployment workflows/custom nodes, AgentBot listener/transport, ownership/message API, current security reports and read-only staging workflow metadata. **No approved first-client business/AI workflow is present in this repository or the inspected staging database.** The single staging workflow is a deterministic phrase responder. It is evidence for the integration contract, not a production capability specification.

The business context requires managed WhatsApp/Instagram automation, tenant boundaries and human takeover; it does not specify an LLM provider/prompt, approved tools, booking/CRM integration, OAuth credentials, production routing, input formats or node allowlist. None was invented or disabled to manufacture security clearance. Inbox continues to own campaigns and provider delivery; n8n is not a substitute sender.

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

Before declaring all material findings non-applicable, approve and version a concrete initial workflow/capability manifest: node types/versions, core modules, credentials/owners, fixed outbound destinations, input formats/size limits, model/tool permissions, expression/template boundaries and error/handoff behavior. Use supported NODES_INCLUDE/EXCLUDE if it matches those actual requirements, and regression-test execution rejection of disallowed nodes; this does not disable vulnerable core services automatically.

This is a genuine missing engineering input. The inspected staged database does not contain an undiscovered production workflow that can be tested instead. Do not silently convert its phrase responder into a commercial AI workflow or assert Git/mail/parser prerequisites are unreachable merely because it omits them.

## Evidence boundary

Staging metadata query read only workflow count and distinct node types; no credential, workflow-parameter or customer-data export. Existing2.43.4 services were not changed. Synthetic acceptance uses isolated2.43.4→2.43.7 databases and generated scoped credentials, not staging data. Candidate results are recorded separately; they establish integration/recovery behavior only for the tested contract.