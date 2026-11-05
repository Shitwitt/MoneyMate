#!/usr/bin/env python3
"""Expose SDK formatting corrections without changing the checked-out source.

The strict format gate remains authoritative and fails the job on any difference.
Only a temporary copy is formatted, for clients unable to download Actions logs.
"""
import base64
import difflib
import gzip
import pathlib
import shutil
import subprocess
import tempfile

root = pathlib.Path.cwd()
with tempfile.TemporaryDirectory(prefix='tink-sdk-format-') as temp:
    target = pathlib.Path(temp)
    shutil.copyfile(root / 'pubspec.yaml', target / 'pubspec.yaml')
    for directory in ['lib', 'test']:
        shutil.copytree(root / directory, target / directory)
    subprocess.run(['dart', 'format', str(target / 'lib'), str(target / 'test')], check=True)
    patch = []
    for directory in ['lib', 'test']:
        for original in sorted((root / directory).rglob('*.dart')):
            relative = original.relative_to(root)
            if 'generated' in relative.parts:
                continue
            before = original.read_text().splitlines(keepends=True)
            after = (target / relative).read_text().splitlines(keepends=True)
            patch.extend(difflib.unified_diff(before, after, fromfile=f'a/{relative}', tofile=f'b/{relative}'))
    text = ''.join(patch)
    (root / 'dart-sdk-format.patch').write_text(text)
    encoded = base64.b64encode(gzip.compress(text.encode())).decode()
    for offset in range(0, len(encoded), 2500):
        print(f'::notice title=SDK format patch {offset // 2500:03d}::{encoded[offset:offset + 2500]}')
