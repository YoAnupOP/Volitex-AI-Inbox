# n8n Inbox control plane

Volitex uses a dedicated account-scoped `AgentBot` for n8n. Do not use an administrator or human-agent API token in n8n.

## Provisioning

Run `bundle exec rails 'volitex:create_n8n_agent_bot[ACCOUNT_ID,https://n8n.example/webhook/volitex-inbox]'` once per customer account. Copy the API token and signing secret from the authenticated dashboard directly into n8n credentials; do not print them in a shell, place them in a workflow node, or commit them. Attach that bot to each inbox that n8n will automate.

## Ownership contract

1. A human turns AI on using the Inbox toggle. The server assigns the configured n8n AgentBot and records `automation_owner=n8n`.
2. Chatwoot delivers events to n8n asynchronously with a delivery ID and HMAC signature. n8n verifies both before processing.
3. n8n may create an outgoing message only while it is the assigned owner. It must send a unique `automation_delivery_id` for every attempted reply. Retries with the same ID return the original message rather than sending another one.
4. A human takes over with the same toggle. The server atomically sets `automation_owner=human`, removes the bot assignment, and only then permits a human reply.
5. If the n8n webhook times out or finally fails after retry, Volitex revokes bot ownership and opens the conversation for human follow-up. n8n must never retry a reply after receiving a non-success response from the Inbox API.

The n8n message request is `POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages` with `api_access_token` set to the dedicated AgentBot token and JSON containing `content`, `message_type: "outgoing"`, and `automation_delivery_id`. A 200 response for an already-used delivery ID is success and must not cause another send.
