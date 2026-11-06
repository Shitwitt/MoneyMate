import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class BuildRetryTest(unittest.TestCase):
    def run_build(self, message, failures):
        helper = Path(__file__).resolve().parents[2] / '.github/scripts/retry_build.py'
        with tempfile.TemporaryDirectory() as folder:
            counter = Path(folder) / 'attempts'
            code = '''from pathlib import Path
import sys
p=Path(sys.argv[1]); n=int(p.read_text())+1 if p.exists() else 1
p.write_text(str(n)); print(sys.argv[2]); raise SystemExit(1 if n<=int(sys.argv[3]) else 0)
'''
            env = {**os.environ, 'TINK_BUILD_RETRY_DELAY_SECONDS': '0'}
            result = subprocess.run([sys.executable, str(helper), sys.executable, '-c', code,
                                     str(counter), message, str(failures)],
                                    env=env, capture_output=True, text=True)
            return result.returncode, int(counter.read_text())

    def test_transient_maven_rate_limit_is_retried(self):
        self.assertEqual(self.run_build('Received status code 429: Too Many Requests', 1), (0, 2))

    def test_compile_errors_are_not_retried(self):
        self.assertEqual(self.run_build('Compilation failed: undefined method', 5), (1, 1))

    def test_retries_are_bounded(self):
        self.assertEqual(self.run_build('HTTP 503 Service Unavailable', 5), (1, 3))


if __name__ == '__main__':
    unittest.main()
