import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[3] / 'deployment/production/workflow_failure_alerts.py'
spec = importlib.util.spec_from_file_location('alerts', SOURCE)
alerts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(alerts)


class WorkflowAlertsTest(unittest.TestCase):
    def test_initialization_sets_boundary_without_sending_history(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(alerts, 'failed_executions', return_value=[]) as query, \
                patch.object(alerts, 'send_alert') as send:
            result = alerts.run_once({}, Path(directory) / 'state.json')
            self.assertTrue(result['initialized'])
            query.assert_called_once()
            send.assert_not_called()

    def test_success_is_recorded_and_not_emailed_again(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'state.json'
            path.write_text(json.dumps({'since': '2026-10-23T00:00:00+00:00', 'notified': []}))
            with patch.object(alerts, 'failed_executions', return_value=[{'id': '7'}]), \
                    patch.object(alerts, 'send_alert') as send:
                self.assertEqual(alerts.run_once({}, path)['alerted'], 1)
                send.assert_called_once()
            with patch.object(alerts, 'failed_executions', return_value=[]) as query, \
                    patch.object(alerts, 'send_alert') as send:
                self.assertEqual(alerts.run_once({}, path)['alerted'], 0)
                self.assertEqual(query.call_args.args[1]['notified'], ['7'])
                send.assert_not_called()

    def test_smtp_failure_does_not_mark_execution_notified(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'state.json'
            path.write_text(json.dumps({'since': '2026-10-23T00:00:00+00:00', 'notified': []}))
            with patch.object(alerts, 'failed_executions', return_value=[{'id': '7'}]), \
                    patch.object(alerts, 'send_alert', side_effect=RuntimeError):
                with self.assertRaises(RuntimeError):
                    alerts.run_once({}, path)
            self.assertEqual(json.loads(path.read_text())['notified'], [])

    def test_query_reads_metadata_only_and_excludes_notified_ids(self):
        result = type('Result', (), {'returncode': 0, 'stdout': ''})()
        with patch.object(alerts.subprocess, 'run', return_value=result) as run:
            alerts.failed_executions({'N8N_DATABASE_CONTAINER': 'synthetic-db'},
                                     {'since': '2026-10-23T00:00:00+00:00', 'notified': ['7']})
        query = run.call_args.kwargs['input']
        self.assertIn('id NOT IN (7)', query)
        self.assertIn('"stoppedAt"', query)
        self.assertNotIn('execution_data', query)


if __name__ == '__main__':
    unittest.main()
