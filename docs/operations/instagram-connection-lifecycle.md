# Volitex AI Inbox Instagram Login connection lifecycle

This describes the direct Instagram Login channel (`Channel::Instagram`), not the legacy Facebook Page flow. It addresses the October 26 audit. Release approval requires the matching source's regression tests and publication gates; an older kit does not contain these fixes.

## Renewal and connection health

- The existing hourly scheduler queues `Channels::Instagram::ConnectionHealthSchedulerJob` on the ordinary worker. Per-channel checks run on `low`; both `scheduled_jobs` and `low` must be consumed.
- Valid tokens approaching expiry within ten days are refreshed only once they are at least 24 hours old. `token_refreshed_at`, rather than generic `updated_at`, tracks issuance/renewal. Customer requests read credentials without waiting for renewal HTTP calls.
- Database row locks reload current credentials before refresh/reconnect updates. Stale instances do not overwrite newer tokens. Credentials remain encrypted using the existing Active Record keys.
- Expired or terminally invalid credentials prompt the existing reconnect warning and administrator notification. Transient failures preserve valid credentials and retry four times with polynomial backoff; exhausted checks queue an administrator operational email, limited to one per channel/day. Configure and verify Rails SMTP separately from n8n's failure monitor. Ensure each managed account routes these administrator notices to a monitored operator mailbox; client-only recipients do not establish operational coverage. Independent monitoring must detect broken SMTP, stopped schedulers, queue starvation or an unavailable operator.
- A daily account-level subscription POST restores the required fields and requires the documented `success: true` response. Reconnect also verifies subscription success before clearing its warning. HTTP 200 alone is insufficient. Interrupted subscription setup is retried against the retained inbox; it does not create another inbox.
- Required subscriptions are `messages,message_reactions,messaging_seen,messaging_postbacks,comments`. Configure those app-level webhook fields, the public HTTPS callback and verification/signature credentials in Meta as well. An account-level subscription cannot repair a missing app-level configuration or app-review permission.
- The API version comes from `INSTAGRAM_API_VERSION`, including profile, send and subscription paths. An API-version upgrade is a separate change; these fixes do not silently select the latest version.

## OAuth and reconnect

Authorization state expires after ten minutes, is consumed once in Redis, and is bound to an encrypted HttpOnly SameSite=Lax browser cookie. Signed claims identify the tenant, initiating administrator, return hint and optional target inbox. Callback validation rechecks administrator membership before exchanging the authorization code. Old signed URLs without expiration are rejected; restart the connect flow after upgrade.

Open the Inbox UI through the same canonical HTTPS origin used by `FRONTEND_URL` before starting OAuth. A cookie created at localhost cannot bind a callback on an unrelated ngrok hostname. After an origin change, use the new origin, start a fresh authorization and update the Meta redirect/webhook configuration where required; do not relax browser binding.

Reconnect must authorize the original Instagram identity for the specified tenant inbox. A different identity cannot silently create a replacement. The callback validates all requested permission grants and the long-lived token/expiry response before persisting credentials. Subscription failure remains visibly repairable; it is not reported as healthy authorization. The installation's existing unique Instagram identity boundary is preserved.

## Inbound messages and outbound policy

Signed inbound DMs/comments already delivered to this installation are retained while authorization is repaired. When profile lookup is unavailable, the channel uses the webhook sender identity and a placeholder name. Normal inbox/source-ID deduplication still applies. Original DM event timestamps are retained so delayed processing does not reopen the reply window. Events Meta never delivers cannot be recovered from a local queue.

Each webhook event is classified independently. Supported postbacks use the same incoming-message/deduplication path. Existing HMAC checks, comment moderation/reply routing and mutex exhaustion behavior remain intact.

Automated DMs are restricted to the standard 24-hour window. Public comments do not open that private DM window. `HUMAN_AGENT` is used only for eligible human replies after 24 hours and within seven days, when the installation flag is enabled. It never extends bot, automation-rule or campaign replies. Dispatch rejects closed windows before calling Meta. Keep the Human Agent flag disabled unless separate Meta approval has been verified; the three Instagram business permissions do not establish that approval.

## Rollout and acceptance

1. Back up the database and preserve encryption keys. Run migrations before the new application/workers. The migration backfills legacy token timestamps from `updated_at` conservatively and does not replace tokens or move tenants.
2. Verify scheduler registration, both worker queues and successful per-channel checks. Inspect timestamp progression using IDs/statuses only; never print credentials or provider response bodies.
3. On an authorized test identity, accept a fresh connect, the original-inbox reconnect and rejection of a different identity. Verify permission cancellation, app/account webhook subscriptions and incoming/outgoing DM/comment behavior.
4. In an isolated test environment, exercise inactive-inbox renewal, expiry/revocation, transient retry exhaustion and mail delivery, interrupted subscription recovery, stale-worker races, mixed batches, duplicate delivery and human-versus-bot windows. Do not expire real client tokens to test recovery.
5. Record actual live Meta acceptance separately from mocked HTTP regressions. This procedure cannot guarantee perpetual authorization: account restrictions, revocation, permission changes and provider outages can still require intervention.

Primary references: [Instagram Business Login](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login/), [refresh requirements](https://developers.facebook.com/docs/instagram-platform/reference/refresh_access_token/), [webhook subscriptions](https://developers.facebook.com/docs/instagram-platform/webhooks/), [Human Agent scope correction](https://github.com/chatwoot/chatwoot/pull/15932), [per-event/postback handling](https://github.com/chatwoot/chatwoot/pull/14237).

## Local verification record

The [October 26 evidence record](evidence/instagram-lifecycle-2026-10-26.json) records 162 passing related Rails examples, three passing hourly-scheduler examples, migration backfill/credential-preservation/index/rollback acceptance, Ruby/frontend lint and monitor Bash syntax validation. HTTP responses were stubbed, including browser-bound connect with flat and documented nested token responses. No real client authorization, credential change or live provider-message delivery was performed. Exact-source CI/publication and actual Meta acceptance are separate gates.
