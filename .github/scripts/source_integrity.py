#!/usr/bin/env python3
"""Fail on SDK-modified tracked source; expose a bounded exact correction patch.

No files are changed. This check runs without signing secrets, before packaging
corresponding source. Generated/ignored files are not part of the source tree.
"""
import base64
import gzip
import subprocess

patch = subprocess.check_output(['git', 'diff', '--binary', 'HEAD', '--'])
if not patch:
    print('Tracked source and dependency lock are unchanged after SDK checks.')
    raise SystemExit(0)
names = subprocess.check_output(['git', 'diff', '--name-only', 'HEAD', '--'], text=True).strip()
message = ('SDK modified tracked source; commit the exact correction and rerun: ' + names)
message = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
print('::error title=Uncommitted SDK source changes::' + message)
encoded = base64.b64encode(gzip.compress(patch)).decode()
if len(encoded) > 85000:
    print('::error title=SDK source patch exceeds review budget::Inspect the Actions diff; no oversized patch was exposed.')
else:
    for offset in range(0, len(encoded), 2500):
        print(f'::notice title=SDK source patch {offset // 2500:03d}::{encoded[offset:offset + 2500]}')
raise SystemExit(1)
