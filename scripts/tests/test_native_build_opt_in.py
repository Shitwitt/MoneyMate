"""Reference UI pushes must run checks/web without compiling either APK."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class NativeBuildOptInTest(unittest.TestCase):
    def test_release_and_direct_gradle_jobs_require_explicit_opt_in(self):
        for name, job, marker in [
            ('build-apk.yml', 'release', '[apk-download]'),
            ('build.yml', 'debug-apk', '[debug-download]'),
        ]:
            workflow = (ROOT / '.github' / 'workflows' / name).read_text()
            match = re.search(r'^  ' + re.escape(job) + r':\n(?:    #.*\n)*    if: (.+)$', workflow, re.M)
            self.assertIsNotNone(match, name)
            gate = match[1]
            self.assertIn("github.event_name == 'workflow_dispatch'", gate)
            self.assertIn("contains(github.event.head_commit.message, '[build-apk]')", gate)
            self.assertIn(marker, gate)
            self.assertNotIn('!contains', gate)
            # A normal UI/check push contains none of the native opt-in markers.
            ui_message = 'Reference UI and calculation checks [ui-only] [web-check]'
            self.assertFalse(any(value in ui_message for value in ('[build-apk]', '[apk-download]', '[debug-download]')))

    def test_direct_gradle_path_and_optional_release_publishing_are_preserved(self):
        debug = (ROOT / '.github/workflows/build.yml').read_text()
        release = (ROOT / '.github/workflows/build-apk.yml').read_text()
        self.assertIn('assembleDebug', debug)
        self.assertIn('flutter build apk --release', release)
        self.assertIn('inputs.publish_download', release)
        self.assertIn('flutter build web', release)


if __name__ == '__main__':
    unittest.main()
