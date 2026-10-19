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
        denied = subprocess.CompletedProcess([], 1, '', 'synthetic collision')
        with patch('subprocess.run', return_value=denied) as calls, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                runpy.run_path(str(HARNESS), run_name='__main__')
        self.assertEqual(calls.call_count, 1)
        self.assertEqual(calls.call_args.args[0][0:3], ('docker', 'network', 'create'))

    def test_cleanup_only_removes_network_created_by_this_run(self):
        created = subprocess.CompletedProcess([], 0, 'synthetic-network', '')
        denied = subprocess.CompletedProcess([], 1, '', 'synthetic volume failure')
        with patch('subprocess.run', side_effect=[created, denied, created]) as calls, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(RuntimeError):
                runpy.run_path(str(HARNESS), run_name='__main__')
        self.assertEqual(calls.call_count, 3)
        self.assertEqual(calls.call_args.args[0][0:3], ('docker', 'network', 'rm'))


if __name__ == '__main__':
    unittest.main()
