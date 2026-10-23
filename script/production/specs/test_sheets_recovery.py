import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

DIRECTORY = Path(__file__).resolve().parents[3] / 'deployment/production'
sys.path.insert(0, str(DIRECTORY))
spec = importlib.util.spec_from_file_location('recovery', DIRECTORY / 'recover_sheets_failure.py')
recovery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recovery)


class RecoveryTest(unittest.TestCase):
    def test_only_complete_current_ownership_snapshot_is_eligible(self):
        snapshot = dict(binding_matches=True, incoming_public=True, ai_owned=True,
                        can_reply=True, existing_reply=False, latest_incoming=True)
        self.assertEqual(recovery.decide(snapshot), 'eligible')
        for key, value, reason in [
            ('binding_matches', False, 'binding_mismatch'),
            ('incoming_public', False, 'not_public_incoming'),
            ('ai_owned', False, 'human_owned'),
            ('can_reply', False, 'reply_window_closed'),
            ('existing_reply', True, 'reply_already_exists'),
            ('latest_incoming', False, 'newer_message_exists'),
        ]:
            with self.subTest(reason=reason):
                self.assertEqual(recovery.decide(dict(snapshot, **{key: value})), reason)

    def test_extracts_original_authenticated_message_id(self):
        data = [{'resultData': {'lastNodeExecuted': 'Read spreadsheet tab',
                 'runData': {'Authorize incoming message': [{'data': {'main': [[
                     {'json': {'verifiedEvent': {'id': 123}}}
                 ]]}}]}}}]
        self.assertEqual(recovery.event_id(json.dumps(data)), 123)

    def test_non_google_failure_is_blocked(self):
        data = [{'resultData': {'lastNodeExecuted': 'Book site visit'}}]
        with self.assertRaises(ValueError):
            recovery.event_id(json.dumps(data))

    def test_workflow_fingerprint_changes_when_actions_change(self):
        self.assertNotEqual(recovery.fingerprint({'nodes': ['Sheets']}),
                            recovery.fingerprint({'nodes': ['Sheets', 'Book']}))

    def test_changed_workflow_blocks_before_dispatch(self):
        with patch.object(recovery, 'query', return_value='{}'), \
                patch.object(recovery, 'docker') as docker:
            with self.assertRaises(ValueError):
                recovery.run({'RECOVERY_WORKFLOW_ID': 'Approved', 'RECOVERY_WORKFLOW_SHA256': 'different'},
                             7, Path('unused.json'))
            docker.assert_not_called()

    def test_uncertain_dispatch_is_reserved_and_not_automatically_repeated(self):
        config = dict(RECOVERY_WORKFLOW_ID='Approved', RECOVERY_WORKFLOW_SHA256=recovery.fingerprint({}),
                      N8N_WORKER_CONTAINER='synthetic-worker', INBOX_WORKER_CONTAINER='synthetic-inbox',
                      RECOVERY_ACCOUNT_ID='2', RECOVERY_INBOX_ID='1', RECOVERY_BOT_ID='1',
                      RECOVERY_WEBHOOK_URL='http://synthetic/webhook/test')
        execution = dict(workflow='Approved', status='error', data='synthetic-retained-context')
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'state.json'
            with patch.object(recovery, 'query', side_effect=['{}', json.dumps(execution)]), \
                    patch.object(recovery, 'event_id', return_value=123), \
                    patch.object(recovery, 'docker', side_effect=[json.dumps([{'Config': {'Cmd': ['worker', '--concurrency=1']}}]),
                                                                  RuntimeError('indeterminate transport')]):
                with self.assertRaises(RuntimeError):
                    recovery.run(config, 7, state, execute=True, cause_resolved=True)
            self.assertEqual(json.loads(state.read_text())['7']['status'], 'dispatch_outcome_pending')
            with patch.object(recovery, 'query', side_effect=['{}', json.dumps(execution)]), \
                    patch.object(recovery, 'event_id', return_value=123), \
                    patch.object(recovery, 'docker', return_value=json.dumps([{'Config': {'Cmd': ['worker', '--concurrency=1']}}])) as docker:
                with self.assertRaises(ValueError):
                    recovery.run(config, 7, state, execute=True, cause_resolved=True)
                self.assertEqual(docker.call_count, 1)

    def test_eligible_dispatch_retains_original_id_and_requires_acceptance(self):
        config = dict(RECOVERY_WORKFLOW_ID='Approved', RECOVERY_WORKFLOW_SHA256=recovery.fingerprint({}),
                      N8N_WORKER_CONTAINER='synthetic-worker', INBOX_WORKER_CONTAINER='synthetic-inbox',
                      RECOVERY_ACCOUNT_ID='2', RECOVERY_INBOX_ID='1', RECOVERY_BOT_ID='1',
                      RECOVERY_WEBHOOK_URL='http://synthetic/webhook/test')
        snapshot = dict(binding_matches=True, incoming_public=True, ai_owned=True,
                        can_reply=True, existing_reply=False, latest_incoming=True, dispatched=True)
        execution = dict(workflow='Approved', status='error', data='synthetic-retained-context')
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(recovery, 'query', side_effect=['{}', json.dumps(execution)]), \
                patch.object(recovery, 'event_id', return_value=123), \
                patch.object(recovery, 'docker', side_effect=[json.dumps([{'Config': {'Cmd': ['worker', '--concurrency=1']}}]),
                                                              'RECOVERY_RESULT=' + json.dumps(snapshot)]) as docker:
            path = Path(directory) / 'state.json'
            result = recovery.run(config, 7, path, execute=True, cause_resolved=True)
            self.assertTrue(result['dispatched'])
            self.assertFalse(result['recovery_accepted'])
            self.assertIn('123', docker.call_args.args)
            self.assertEqual(json.loads(path.read_text())['7']['status'], 'queued_unverified')


if __name__ == '__main__':
    unittest.main()
