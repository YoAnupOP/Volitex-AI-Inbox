"""Cleanup ownership checks; no Docker service or credentials required."""
import contextlib
import io
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch

HARNESS = Path(__file__).resolve().parents[2] / 'verify_n8n_acceptance.py'


class CleanupOwnershipTest(unittest.TestCase):
    def test_rejected_network_creation_never_removes_existing_network(self):
        source = subprocess.CompletedProcess([], 0, '0' * 40, '')
        denied = subprocess.CompletedProcess([], 1, '', 'synthetic collision')
        with patch('sys.argv', [str(HARNESS), '--app-image', 'synthetic:source', '--source-sha', '0' * 40]), \
                patch('subprocess.run', side_effect=[source, denied]) as calls, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                runpy.run_path(str(HARNESS), run_name='__main__')
        self.assertEqual(calls.call_count, 2)
        self.assertEqual(calls.call_args.args[0][0:3], ('docker', 'network', 'create'))

    def test_cleanup_only_removes_network_created_by_this_run(self):
        source = subprocess.CompletedProcess([], 0, '0' * 40, '')
        created = subprocess.CompletedProcess([], 0, 'synthetic-network', '')
        denied = subprocess.CompletedProcess([], 1, '', 'synthetic network setup failure')
        with patch('sys.argv', [str(HARNESS), '--app-image', 'synthetic:source', '--source-sha', '0' * 40]), \
                patch('subprocess.run', side_effect=[source, created, denied, created]) as calls, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                runpy.run_path(str(HARNESS), run_name='__main__')
        self.assertEqual(calls.call_count, 4)
        self.assertEqual(calls.call_args.args[0][0:3], ('docker', 'network', 'rm'))


if __name__ == '__main__':
    unittest.main()
