"""The exact-source gate must not mutate source or silently ignore SDK drift."""
import base64
from contextlib import redirect_stdout
import gzip
import io
import os
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / '.github/scripts/source_integrity.py'


class SourceIntegrityTest(unittest.TestCase):
    def run_gate(self, replies):
        stdout = io.StringIO()
        with patch('subprocess.check_output', side_effect=replies) as command, redirect_stdout(stdout):
            with self.assertRaises(SystemExit) as result:
                runpy.run_path(str(SCRIPT), run_name='__main__')
        return result.exception.code, stdout.getvalue(), command

    def test_clean_source_passes_with_no_patch_or_mutating_command(self):
        code, output, command = self.run_gate([b''])
        self.assertEqual(code, 0)
        self.assertIn('unchanged', output)
        self.assertNotIn('::error', output)
        command.assert_called_once_with(['git', 'diff', '--binary', 'HEAD', '--'])

    def test_drift_fails_and_emits_an_exact_bounded_patch_without_applying_it(self):
        diff = b'diff --git a/pubspec.lock b/pubspec.lock\n--- a/pubspec.lock\n+++ b/pubspec.lock\n@@ -1 +1 @@\n-old\n+new\n'
        code, output, command = self.run_gate([diff, 'pubspec.lock\n'])
        self.assertEqual(code, 1)
        self.assertIn('Uncommitted SDK source changes', output)
        encoded = ''.join(line.split('::', 2)[2] for line in output.splitlines() if line.startswith('::notice title=SDK source patch'))
        self.assertEqual(gzip.decompress(base64.b64decode(encoded)), diff)
        self.assertTrue(all(call.args[0][:2] == ['git', 'diff'] for call in command.call_args_list))

    def test_oversized_diff_still_fails_but_does_not_flood_annotations(self):
        code, output, _ = self.run_gate([os.urandom(100000), 'fictional.bin'])
        self.assertEqual(code, 1)
        self.assertIn('exceeds review budget', output)
        self.assertNotIn('::notice title=SDK source patch', output)


if __name__ == '__main__':
    unittest.main()
