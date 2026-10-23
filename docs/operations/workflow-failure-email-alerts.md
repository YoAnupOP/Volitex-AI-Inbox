# Volitex AI Inbox workflow failure email alerts

`deployment/production/workflow_failure_alerts.py` reads only n8n execution IDs,
workflow IDs, terminal error/crashed statuses and timestamps. It emails these
metadata fields through certificate-verified STARTTLS SMTP. It never reads
execution bodies or credentials from n8n and never replays customer automations.
Keep n8n's restricted node policy unchanged; the Send Email node is not enabled.

## Private configuration

Create `/etc/volitex/workflow-alerts.env` with mode 0600 and these keys:

```dotenv
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=<sender-address>
SMTP_PASSWORD=<Google-App-Password>
MAILER_SENDER_EMAIL=Volitex AI Inbox <sender-address>
ALERT_EMAIL_TO=<operator-address>
ALERT_ENVIRONMENT=production
N8N_DATABASE_CONTAINER=<actual-n8n-postgres-container-name>
```

The database container must expose its normal POSTGRES_USER and POSTGRES_DB.
Alternatively omit N8N_DATABASE_CONTAINER and set N8N_DATABASE_URL; install the
PostgreSQL client on the host. Docker access is privileged; run the service only
as the trusted deployment operator. Protect the configuration, state and logs.

## Installation and acceptance

1. Place the verified source at `/opt/volitex-ai-inbox`. Create protected
   `/var/lib/volitex` and configure the actual database and SMTP account.
2. Run the script once with `--config /etc/volitex/workflow-alerts.env --state
   /var/lib/volitex/workflow-alerts.json`. First run verifies database access and
   records a monitoring boundary, without emailing historical failures. Review
   existing failures separately; initialization does not resolve them.
3. Install the adjacent `volitex-workflow-alerts.service` and `.timer` into
   `/etc/systemd/system`, then run `systemctl daemon-reload` and
   `systemctl enable --now volitex-workflow-alerts.timer`.
4. Cause a clearly labelled synthetic failure without customer/provider actions.
   Verify the received email, run again to confirm deduplication, and verify
   persistence after an operator-approved reboot. Check the service journal.
5. Have an independent monitor alert if this timer stops or SMTP/database access
   fails. A broken email transport cannot reliably email its own failure.

Every poll handles up to 20 unnotified failures. Notifications are recorded only
after SMTP acceptance. An interrupted process between sending and recording may
send a duplicate; delivery is at-least-once, not exactly-once. Recipient delivery
still needs an actual mailbox check. State must survive upgrades; deleting it
resets the boundary and can miss existing failures. A local Windows scheduled
task covers only periods when the PC, Docker and signed-in operator are available;
it does not establish server monitoring or 24/7 incident response.

This monitor covers terminal execution failures. Semantic rejection statuses in
successful executions, stuck executions, service/queue health, backup failures,
alert delivery failure and actual operator response require the separate
operational acceptance checks in the first-client runbook.

## Recovery

An alert does not claim that no external action occurred. Inspect current human
ownership and the destination's committed state, fix the cause, then replay only
the original authenticated event through the existing tenant checks and stable
reply idempotency key. Do not mint a new message ID or blindly replay a booking,
payment or other non-idempotent action. Automatic recovery is not enabled by this
monitor. The Sheets demo's sequential reserved-row replay is a narrower guarantee.
