# Isolated WhatsApp verification — approval required before live sends

The Heroku/buildpack App Review deployment at `inbox.volitexai.tech` is outside this candidate test. Its application, Meta callback, connected inboxes and traffic must remain unchanged. The previously shared token is compromised: revoke it and configure a replacement only through a protected credential store. It was not reused.

## Current evidence

- PASS: Windows resolved `graph.facebook.com` and completed an unauthenticated TLS request to `/v24.0/`, receiving HTTP 400 / GraphMethodException code 100. This proves basic connectivity only.
- BLOCKED: authenticated app/WABA/phone-number access, recipient allowlist, fresh token validity/scopes and current delivery eligibility have not been checked.
- NOT RUN: direct Graph sends, actual WhatsApp receipt, live inbound selections or the complete Inbox/n8n reply path.
- Local/provider specs and the private synthetic n8n queue probe are separate evidence; neither proves Meta delivery.

## Safest staging arrangement

Use a separate development Meta app, its own Meta test WABA/phone-number resources and an explicitly authorized recipient. Do not subscribe another app to the existing live WABA or change the App Review app's callback as part of this test.

Run the candidate Inbox and a separate n8n main/worker on existing local hardware or an already authorized non-production environment, with fresh disposable PostgreSQL/Valkey databases, volumes, encryption keys and account-scoped AgentBot credentials. Bind service ports to localhost. A separately approved HTTPS ingress/tunnel may expose only the staging Meta webhook callback; it must not expose databases, workers or unauthenticated administration. Do not provision paid infrastructure or change DNS automatically.

Use the candidate's `GET/POST /webhooks/whatsapp/:phone_number` routes on that separate ingress. Configure only the new app's callback and its test WABA subscription. Its signature secret must match that app and the staging channel. The n8n workflow receives events from staging Inbox, not directly from Meta, and must enforce the documented HMAC, timestamp, delivery ID and ownership contract.

This is a proposed configuration, not an existing or deployed staging environment. Verify the separate app/resources are available before making changes. If isolation cannot be achieved, retain the live-test blocker rather than redirecting existing traffic.

## Read-only authenticated prerequisites

Once the operator has replaced the token and identified the target account/number, use a protected API client with redacted request logging to:

1. Inspect token validity, app identity, expiry and required WhatsApp messaging/management permissions without printing the token or app secret.
2. Read the test WABA's phone numbers and confirm the exact phone-number ID, registration/status and test recipient allowlist.
3. Read app/WABA subscriptions and verify only the intended isolated callback will receive this test traffic.
4. Confirm the configured Graph API version remains supported; the repository currently defaults to v24.0. Do not silently upgrade it based on an unauthenticated probe.
5. Confirm the participant will initiate the customer-service window before interactive sends.

The [Meta-maintained Cloud API collection](https://www.postman.com/meta/whatsapp-business-platform/documentation/wlk6lh4/whatsapp-cloud-api) is the prerequisite/request reference. Current app access and permissions remain unverified until authenticated checks succeed.

## Proposed live test — wait for explicit approval

First propose the exact test sender, recipient, environment and message budget. No real customer may be used.

**Phase 1: direct API delivery, two business messages.** The authorized participant sends an inbound test message. During the open service window, send one two-button interactive message and one four-row list to that recipient through the fresh protected Graph client. Record redacted message IDs, actual receipt, one selection per format and signed delivery/inbound callbacks. This validates provider connectivity only; it does not validate Quick Menus or n8n.

**Phase 2: full staging flow, up to eleven business messages.** In the correct staging account, create one three-button Quick Menu and one four-row list, send both through the conversation composer, and have the participant select all seven titles. Verify seven bounded n8n replies through the dedicated AgentBot API, one normal text reply and one human reply after takeover. Verify duplicate replay creates no additional reply; missing/invalid signatures, closed windows and cross-account IDs are rejected; a bot attempt after takeover is rejected. No extra live sends are needed for negative cases.

Require separate approval for each phase after prerequisites pass. The participant's inbound messages are voluntary test actions. If any provider or security check fails, stop live sends, retain redacted evidence and investigate offline.

## Synthetic test boundary

`bash script/production/verify_n8n_queue.sh` creates a private Compose project using the existing pinned n8n/PostgreSQL/Valkey images and disposable credentials. It imports only the committed synthetic response fixture into its own database, checks that a response-node webhook waits while no worker exists, then checks worker-driven response and recorded execution. It cleans up only that project. It never contacts Meta or imports into the existing n8n instance.

The fixture is not the production HMAC/automation workflow and does not send a reply through Inbox. The complete signed Inbox → production workflow → Inbox API integration remains a separate required staging check. The [n8n server CLI](https://docs.n8n.io/deploy/host-n8n/configure-n8n/use-the-command-line.md) and [queue mode documentation](https://docs.n8n.io/deploy/host-n8n/configure-n8n/scaling/enable-queue-mode.md) informed the disposable import/publish procedure.
