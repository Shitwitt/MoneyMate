"""Packaging-only regressions; no Flutter installation or network required."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'create_web_cache.py'


class OfflineCacheTests(unittest.TestCase):
    def fixture(self, base, manifest):
        root = Path(base) / 'build/web'
        (root / 'assets/assets/fonts').mkdir(parents=True)
        (root / 'index.html').write_text('<html>fictional fixture</html>')
        (root / 'assets/assets/fonts/Inter-Regular.ttf').write_bytes(b'fixture font')
        (root / 'assets/FontManifest.json').write_text(json.dumps(manifest))
        return root

    def run_packager(self, base):
        return subprocess.run([sys.executable, str(SCRIPT)], cwd=base, capture_output=True, text=True)

    def test_engine_fallback_uses_existing_inter_and_is_cached(self):
        with tempfile.TemporaryDirectory() as base:
            regular = {'asset': 'assets/fonts/Inter-Regular.ttf', 'weight': 400}
            root = self.fixture(base, [{'family': 'Inter', 'fonts': [regular]}])
            result = self.run_packager(base)
            self.assertEqual(result.returncode, 0, result.stderr)
            manifest = json.loads((root / 'assets/FontManifest.json').read_text())
            self.assertEqual(manifest[-1], {'family': 'Roboto', 'fonts': [regular]})
            worker = (root / 'service-worker.js').read_text()
            self.assertIn('./assets/FontManifest.json', worker)
            self.assertIn('./assets/assets/fonts/Inter-Regular.ttf', worker)
            self.assertNotIn('fonts.gstatic.com', worker)
            self.assertEqual((root / 'assets/assets/fonts/Inter-Regular.ttf').read_bytes(), b'fixture font')

    def test_repeated_packaging_is_idempotent(self):
        with tempfile.TemporaryDirectory() as base:
            root = self.fixture(base, [{'family': 'Inter', 'fonts': [{'asset': 'assets/fonts/Inter-Regular.ttf'}]}])
            self.assertEqual(self.run_packager(base).returncode, 0)
            first = (root / 'service-worker.js').read_bytes()
            self.assertEqual(self.run_packager(base).returncode, 0)
            self.assertEqual((root / 'service-worker.js').read_bytes(), first)
            self.assertEqual(sum(f['family'] == 'Roboto' for f in json.loads((root / 'assets/FontManifest.json').read_text())), 1)

    def test_debug_engine_fallback_is_local_and_bundled(self):
        repo = SCRIPT.parent.parent
        bootstrap = (repo / 'web/flutter_bootstrap.js').read_text()
        self.assertIn("new URL('fallback-fonts/', document.baseURI)", bootstrap)
        self.assertNotIn('https://', bootstrap)
        font = repo / 'web/fallback-fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'
        self.assertEqual(font.read_bytes()[:4], b'wOF2')
        self.assertGreater(font.stat().st_size, 10000)

    def test_missing_local_font_fails_instead_of_going_online(self):
        with tempfile.TemporaryDirectory() as base:
            self.fixture(base, [])
            result = self.run_packager(base)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Bundled Inter is required', result.stderr)


if __name__ == '__main__':
    unittest.main()
