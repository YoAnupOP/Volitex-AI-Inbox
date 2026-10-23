import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

DIRECTORY = Path(__file__).resolve().parents[3] / 'deployment/production'
sys.path.insert(0, str(DIRECTORY))
spec = importlib.util.spec_from_file_location('campaign_alerts', DIRECTORY / 'campaign_failure_alerts.py')
alerts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(alerts)


class CampaignAlertsTest(unittest.TestCase):
    def test_initialization_does_not_email_historical_failures(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(alerts, 'campaign_failures', return_value=[]), \
                patch.object(alerts, 'send_campaign_alert') as send:
            self.assertTrue(alerts.run_once({}, Path(directory) / 'state.json')['initialized'])
            send.assert_not_called()

    def test_repeat_state_is_deduplicated_but_new_failure_count_alerts(self):
        campaign = dict(id=1, account_id=2, campaign_status=2, failed=1, unknown=0)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'state.json'
            path.write_text(json.dumps({'since': '2026-10-23T00:00:00+00:00', 'notified': []}))
            with patch.object(alerts, 'campaign_failures', return_value=[campaign]), \
                    patch.object(alerts, 'send_campaign_alert') as send:
                self.assertEqual(alerts.run_once({}, path)['alerted'], 1)
                self.assertEqual(alerts.run_once({}, path)['alerted'], 0)
                send.assert_called_once()
            with patch.object(alerts, 'campaign_failures', return_value=[dict(campaign, unknown=1)]), \
                    patch.object(alerts, 'send_campaign_alert'):
                self.assertEqual(alerts.run_once({}, path)['alerted'], 1)

    def test_smtp_failure_remains_unnotified(self):
        campaign = dict(id=1, account_id=2, campaign_status=2, failed=0, unknown=1)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'state.json'
            path.write_text(json.dumps({'since': '2026-10-23T00:00:00+00:00', 'notified': []}))
            with patch.object(alerts, 'campaign_failures', return_value=[campaign]), \
                    patch.object(alerts, 'send_campaign_alert', side_effect=RuntimeError):
                with self.assertRaises(RuntimeError):
                    alerts.run_once({}, path)
            self.assertEqual(json.loads(path.read_text())['notified'], [])

    def test_query_is_whatsapp_only_and_reads_no_recipient_content(self):
        result = type('Result', (), dict(returncode=0, stdout=''))()
        with patch.object(alerts.subprocess, 'run', return_value=result) as run:
            alerts.campaign_failures(dict(INBOX_DATABASE_CONTAINER='synthetic', INBOX_DATABASE_USER='postgres',
                                         INBOX_DATABASE_NAME='synthetic'), {'since': '2026-10-23T00:00:00+00:00'})
        sql = run.call_args.kwargs['input']
        self.assertIn("i.channel_type='Channel::Whatsapp'", sql)
        self.assertIn("r.state IN ('failed','unknown')", sql)
        self.assertNotIn('phone_number', sql)
        self.assertNotIn('provider_message_id', sql)
        self.assertNotIn('UPDATE', sql)

    def test_unknown_alert_warns_against_blind_resend(self):
        config = dict(ALERT_ENVIRONMENT='synthetic', MAILER_SENDER_EMAIL='from@example.invalid',
                      ALERT_EMAIL_TO='to@example.invalid')
        with patch.object(alerts, 'deliver_email') as deliver:
            alerts.send_campaign_alert(config, dict(id=1, account_id=2, campaign_status=5, failed=0, unknown=1))
        message = deliver.call_args.args[1]
        self.assertIn('never retries or resends', message.get_content())
        self.assertIn('WhatsApp campaign failure alert', message['Subject'])


if __name__ == '__main__':
    unittest.main()
