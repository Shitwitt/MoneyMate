"""Source/licence/packaging invariants for the 2026 compatibility adaptation."""
import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Paisa2026ProvenanceTest(unittest.TestCase):
    def test_pinned_legacy_excerpts_match_manifest_and_are_not_runtime_code(self):
        folder = ROOT / 'third_party/paisa_6_3_6'
        manifest = json.loads((folder / 'SOURCE_MANIFEST.json').read_text())
        self.assertEqual(manifest['commit'], '369aee29ebf51dd5007deca2bb414917f12b208a')
        self.assertEqual(manifest['verified_pubspec_version'], '6.3.6+636')
        self.assertEqual(manifest['license'], 'GPL-3.0-or-later')
        self.assertGreaterEqual(len(manifest['files']), 15)
        for entry in manifest['files']:
            path = ROOT / entry['reference_path']
            self.assertTrue(path.name.endswith('.dart.txt'))
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry['sha256'])
            self.assertNotIn('pubspec', entry['upstream_path'])
            self.assertNotIn('keystore', entry['upstream_path'])
        self.assertEqual(list(folder.rglob('*.dart')), [])

    def test_copyleft_original_mit_and_modification_notices_are_bundled(self):
        original = (ROOT / 'LICENSES/Tink-original-MIT.txt').read_text()
        self.assertTrue(original.startswith('MIT License'))
        self.assertIn('Copyright (c) 2026 PaisaClone contributors', original)
        gpl = (ROOT / 'third_party/paisa_6_3_6/LICENSE.txt').read_bytes()
        self.assertIn(b'Copyright (C) 2022 Hemanth S', gpl)
        self.assertIn(b'either version 3 of the License', gpl)
        self.assertIn(b'GNU GENERAL PUBLIC LICENSE', gpl)
        self.assertEqual((ROOT / 'assets/licenses/GPL-3.0-or-later.txt').read_bytes(), gpl)
        self.assertEqual((ROOT / 'assets/licenses/Tink-original-MIT.txt').read_text(), original)
        self.assertIn('GPL-3.0-or-later', (ROOT / 'LICENSE').read_text())
        self.assertEqual((ROOT / 'assets/licenses/Paisa-compatibility-NOTICE.txt').read_text(),
                         (ROOT / 'third_party/paisa_6_3_6/NOTICE.md').read_text())
        main = (ROOT / 'lib/main.dart').read_text()
        for name in ['GPL-3.0-or-later.txt', 'Tink-original-MIT.txt', 'Paisa-compatibility-NOTICE.txt']:
            self.assertIn('assets/licenses/' + name, main)
        self.assertIn('    - assets/licenses/', (ROOT / 'pubspec.yaml').read_text())

    def test_version_is_updated_consistently_without_changing_package_identity(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text()
        version = re.search(r'^version: ([\d.]+)\+(\d+)$', pubspec, re.M)
        self.assertIsNotNone(version)
        self.assertEqual(version.group(1), '2026.11.6')
        self.assertEqual(version.group(2), '6')
        self.assertIn("const appVersion = '2026.11.6';", (ROOT / 'lib/core/utils/constants.dart').read_text())
        ios = (ROOT / 'ios/PaisaWidgets/Info.plist').read_text()
        self.assertRegex(ios, r'CFBundleShortVersionString</key>\s*<string>2026\.11\.6</string>')
        self.assertRegex(ios, r'CFBundleVersion</key>\s*<string>6</string>')
        self.assertIn('com.example.paisaclone', (ROOT / 'android/app/build.gradle').read_text())

    def test_browser_fixture_is_fictional_and_matches_the_dart_schema_fixture(self):
        literal = (ROOT / 'test/fixtures/paisa_636.dart').read_text().split('Json legacy636Fixture() => ', 1)[1].split('\n};', 1)[0] + '\n}'
        literal = re.sub(r'^\s*//.*$', '', literal, flags=re.M)
        literal = re.sub(r'0x[0-9a-fA-F]+', lambda m: str(int(m[0], 16)), literal)
        literal = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'", lambda m: json.dumps(m[1]), literal)
        literal = re.sub(r',\s*([}\]])', r'\1', literal)
        self.assertEqual(json.loads(literal), json.loads((ROOT / 'test/fixtures/paisa_636.json').read_text()))
        browser = (ROOT / '.github/scripts/reference_2026_smoke.cjs').read_text()
        self.assertIn("page.waitForEvent('filechooser')", browser)
        self.assertIn('Category exclusions were lost in CSV export', browser)
        self.assertIn('Retained original legacy JSON changed', browser)
        self.assertIn("button('Exit Demo').click()", browser)
        self.assertIn("require('./reference_2026_smoke.cjs')", (ROOT / '.github/scripts/web_smoke.cjs').read_text())
        evidence = (ROOT / '.github/scripts/reference_2026_evidence.py').read_text()
        self.assertIn('sha256', evidence)
        self.assertIn('Missing 2026 evidence', evidence)
        self.assertIn('review-2026:', (ROOT / '.github/workflows/build-apk.yml').read_text())

    def test_license_checks_and_same_commit_source_are_required_for_apk_publication(self):
        verifier = (ROOT / '.github/scripts/verify_apk.py').read_text()
        publisher = (ROOT / '.github/scripts/publish_apk.py').read_text()
        self.assertIn('assets/licenses', verifier)
        self.assertIn('GPL-3.0-or-later', verifier)
        self.assertIn('Source commit does not match', publisher)
        self.assertIn('paisa_legacy_decoder.dart', publisher)
        self.assertIn('Tink-source.zip.sha256', publisher)


if __name__ == '__main__':
    unittest.main()
