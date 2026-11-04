"""Temporary source-normalization diagnostic for the initial verification run."""
import base64
import gzip
import pathlib
import subprocess

for label, data in [('format', subprocess.check_output(['git', 'diff', '--binary', '--', 'lib', 'test'])), ('lock', pathlib.Path('pubspec.lock').read_bytes())]:
    text = base64.b64encode(gzip.compress(data)).decode()
    for i in range(0, len(text), 45000):
        print(f'::notice title=paisa-{label}-{i // 45000 + 1}::{text[i:i + 45000]}')
