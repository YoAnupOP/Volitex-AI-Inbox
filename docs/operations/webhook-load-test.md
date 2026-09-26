# Staging webhook load test

This harness measures acknowledgement latency and HTTP error rate against an isolated staging deployment. It does not produce a safe production capacity number and refuses the production Volitex hostnames unless explicitly overridden.

Use test WhatsApp phone-number IDs or Instagram account IDs that already exist in the staging database. The app secret is read from an environment variable so it does not appear in shell history or process arguments.

```bash
export LOAD_TEST_META_APP_SECRET='<staging-meta-app-secret>'
ruby script/production/webhook_load_test.rb \
  --base-url https://staging-inbox.example.com \
  --channel whatsapp \
  --tenants '<phone-number-id-1>,<phone-number-id-2>,<phone-number-id-3>' \
  --events 300 \
  --duplicates 1 \
  --concurrency 30
```

For Instagram, use the configured Instagram business account IDs and `--channel instagram`. The payloads are signed with `X-Hub-Signature-256` and duplicate deliveries reuse the same provider message ID, so the result can be checked against the staging message count.

Run the matrix below one scenario at a time and record the JSON output together with CPU, RAM, PostgreSQL connections, Redis memory, Sidekiq queue lengths, and n8n queue age. Pause or stop n8n only in staging when testing downstream failure behavior.

| Scenario | Expected result |
| --- | --- |
| Multiple tenants, no duplicates | Successful acknowledgements with tenant-local messages |
| Duplicate deliveries | One inbound message per provider message ID |
| Burst concurrency | No sustained HTTP failures; queue drains after the burst |
| n8n slow or unavailable | Inbound messages persist; bounded AgentBot retries occur; final exhaustion hands off to a human |
| Redis unavailable | Webhook requests fail rather than acknowledging an event that was not queued; Meta retries |
| PostgreSQL unavailable | Health/readiness fails and webhook requests fail; no partial message is acknowledged |
| Worker stopped | Webhook acknowledgements continue only while Sidekiq durably accepts jobs; queued work drains after restart |

Do not run this against `inbox.volitexai.tech` or a client's Meta account. Measure the first KVM 4 after provisioning using the same matrix; do not infer a messages-per-minute limit from a local laptop.
