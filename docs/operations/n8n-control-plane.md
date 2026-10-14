# n8n Inbox control plane

Volitex uses a dedicated account-scoped `AgentBot` for n8n. Do not use an administrator or human-agent API token in n8n.

## Provisioning

Run `bundle exec rails 'volitex:create_n8n_agent_bot[ACCOUNT_ID,https://automation.volitexai.tech/webhook/volitex-inbox]'` once per customer account. Copy the API token and signing secret from the authenticated dashboard directly into n8n credentials; do not print them in a shell, place them in a workflow node, or commit them. Attach that bot to each inbox that n8n will automate.

The destination is the active production webhook workflow on the private n8n queue deployment documented in [`.env.n8n.example`](../../deployment/.env.n8n.example). The Coolify proxy exposes only `n8n-main`; workers are never public endpoints.

## Inbox webhook authentication

Inbox sends the n8n webhook as JSON with these headers:

| Header | Value |
|---|---|
| `X-Chatwoot-Delivery` | unique delivery ID; retain it for the workflow's duplicate handling |
| `X-Chatwoot-Timestamp` | Unix timestamp used to sign the payload |
| `X-Chatwoot-Signature` | `sha256=<HMAC-SHA256(signing_secret, "#{timestamp}.#{raw_body}")>` |

n8n must verify the signature against the exact unmodified request body, reject a missing or invalid signature, and apply its own replay/duplicate handling to the delivery ID before processing.

## Ownership contract

1. A human turns AI on using the Inbox toggle. The server assigns the configured n8n AgentBot and records `automation_owner=n8n`.
2. Inbox delivers events to n8n asynchronously with the authenticated delivery ID and HMAC signature above. n8n verifies both before processing.
3. n8n may create an outgoing message only while it is the assigned owner. It must send a unique `automation_delivery_id` for every attempted reply. Retries with the same ID return the original message rather than sending another one.
4. A human takes over with the same toggle. The server atomically sets `automation_owner=human`, removes the bot assignment, and only then permits a human reply.
5. If the Inbox-to-n8n webhook times out or finally fails after retry, Volitex revokes bot ownership and opens the conversation for human follow-up. n8n must never retry a reply after receiving a non-success response from the Inbox API.

The n8n message request is `POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages` with the `api_access_token` request header set to the dedicated AgentBot token and JSON containing `content`, `message_type: "outgoing"`, and `automation_delivery_id`. A 200 response for an already-used delivery ID is success and must not cause another send.

An n8n-to-Inbox outgoing REST API failure is an automation/API failure: handle it with the workflow's bounded retry, idempotency key, alerting, and human operating procedure. It is **not** the Inbox-side human-handoff signal. Only final failure of the Inbox-to-n8n AgentBot webhook triggers that automatic handoff.

## Implemented staging workflow

`deployment/n8n/inbox-reply.workflow.json` uses the existing AgentBot outgoing webhook, not an additional account webhook. The Compose file loads the reviewed `deployment/n8n/custom` credential and node files on both main and worker. No npm package installation or secret-bearing workflow parameters are needed.

Import the workflow inactive. Create the `Volitex account AgentBot` credential in n8n's encrypted credential store, set its trusted Inbox URL, account/inbox/bot IDs, account-scoped API token and signing secret, and select that credential in both custom nodes. The committed credential reference is a staging identifier, not a credential value. Import/publish with the existing n8n CLI or authenticated editor, then restart main/worker after CLI publication. Never export decrypted credentials into source control. Back up n8n PostgreSQL and preserve `N8N_ENCRYPTION_KEY` before changes.

Sequence: raw-body Webhook → Validate webhook → Respond to Webhook → Send reply. Validation authenticates exact bytes, applies a five-minute timestamp bound, and checks credential-bound account/inbox context. Invalid authentication returns 401; foreign context returns 403. The signed receiver acknowledges valid events before calling the Inbox API, so subsequent API failure cannot become an Inbox webhook-failure handoff signal.

The reply node reads the authoritative conversation, verifies contact and inbox, checks ownership and service window, and uses only its assigned AgentBot credential. It replies only to the exact staging test phrase `Volitex round trip`. It ignores other events, private notes and outgoing messages. Do not treat this deterministic smoke-test workflow as a client's production business workflow.

The idempotency key is `incoming:<account_id>:<inbox_id>:<incoming_message_id>`, independent of the webhook delivery UUID. Inbox stores it in message content attributes and enforces a unique index scoped to conversation and bot. It leaves `source_id` empty until the channel supplies the provider ID. A later replay returns the existing message even after provider delivery.

The reply node retries indeterminate transport failures at most three times, two seconds apart, with the same key and a new ownership check. It does not retry definite API rejections. Warning/error logs contain only execution/account/message IDs and status codes; workflow execution body/progress retention is disabled. Operators must alert on `inbox_api_rejected` and exhausted `inbox_unavailable` failures and follow up with human takeover. There is no automatic reply after explicit human ownership.

For multiple clients, keep one shared n8n instance. Use a separate credential and unique webhook/workflow identity per account/inbox; never choose an API credential or destination URL from an incoming payload. The production Inbox URL should use TLS. When an internal Docker hostname is necessary, add only that exact trusted hostname to `N8N_SSRF_ALLOWED_HOSTNAMES`; leave SSRF protection enabled and its default blocked ranges intact. The local test hostname allowance is staging configuration, not a production wildcard.

Deployment requires `bundle exec rails db:migrate` for migration `20261014000000`. It creates a concurrent unique index without modifying message rows. Back up first; existing duplicate automation keys cause migration failure and must be investigated rather than deleted automatically. An interrupted concurrent index build can leave an invalid index; inspect PostgreSQL index validity before an operator-approved repair/retry. Rolling back the migration removes uniqueness protection, so stop automation before rolling back the application.

Live and failure-test evidence is in [the integration report](inbox-n8n-round-trip-2026-10-14.md). n8n runtime security approval remains separate from functional success.
