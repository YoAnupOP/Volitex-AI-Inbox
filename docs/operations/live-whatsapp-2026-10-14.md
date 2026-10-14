# Local live WhatsApp verification — 2026-10-14

## Scope and provenance

Operator approved the bounded text/button/list test and identified the authorized handset by its last four digits. No other recipient was contacted. Existing encrypted local channel credentials were used without exporting them. No production deployment or image publication occurred.

Runtime source: `38229d6009cac43c86066296275ae629fd5b0d9e`.
Local application image identity: `sha256:65ed1483496563f13add97de1970e415e20dd43b8229a97e221db06b6218b65b` (not a published registry release digest).
Account 1, inbox 3, conversation 1; local Docker PostgreSQL and worker.

## Executed results

| Check | Result | Evidence |
| --- | --- | --- |
| Live inbound message | PASS | Message 7 at 06:27:42.648 UTC reached the expected local conversation. |
| Normal authenticated Inbox API reply | PASS | Message 8, created 06:33:20.955 UTC; provider ID recorded; read status at 06:33:31.364 UTC. |
| Three-button Quick Menu | PASS | Created through account CRUD API, menu 3; sent through conversation `send_quick_menu`, message 9; read status at 06:33:31.448 UTC. |
| Four-row list Quick Menu | PASS | Created through account CRUD API, menu 4; sent through conversation `send_quick_menu`, message 10; read status at 06:33:31.583 UTC. |
| Actual handset receipt and display | PASS | Operator confirmed receipt of all three messages and correct layouts/titles. This supplements provider status; HTTP acceptance alone was not used as delivery evidence. |
| Button inbound visible title | PASS | Message 11, `Confirm buttons`, 06:33:58.623 UTC. |
| List inbound visible title | PASS | Message 12, `Confirm list`, 06:34:01.841 UTC. |
| Agent attribution | PASS | All three outgoing messages have User sender ID 1. |
| Inbox → n8n → Inbox automated reply | BLOCKED | Read-only PostgreSQL workflow query returned zero n8n workflows; local account has zero webhooks. No automated reply was attempted. |
| Live duplicate/retry/human-handoff verification | NOT RUN | Requires the authenticated n8n control-plane workflow and a separately bounded live test. |

The live sends used protected agent authentication with `POST /api/v1/accounts/1/conversations/1/messages` for text, `POST /api/v1/accounts/1/quick_menus` for CRUD, and `POST /api/v1/accounts/1/conversations/1/send_quick_menu` for menus. Before sending, the runner checked the expected account/inbox/recipient and open service window. A content marker prevented accidentally rerunning the same three-message batch.

Diagnostics ran as private temporary Rails runner scripts via `docker exec … bundle exec rails runner`; results were inspected as whitelisted metadata. No message recipient, access token, app secret, or raw webhook body is recorded here.

## Remaining gates

Configure and verify an account-scoped AgentBot workflow following `n8n-control-plane.md`: exact-body HMAC, timestamp/replay checks, duplicate handling, ownership enforcement, and idempotent Inbox replies. The healthy queue/main/worker stack by itself does not establish this integration.

Material n8n runtime vulnerabilities remain a release blocker from the preceding security assessment. This successful live test does not resolve image-security, repository-wide CI, campaign crash/retry safety, or first-server operational gates. The candidate is not declared production-ready.
