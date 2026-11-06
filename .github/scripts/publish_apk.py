#!/usr/bin/env python3
"""Publish an already-verified APK with retryable, idempotent release uploads."""
import hashlib
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import time
import zipfile

source = Path(sys.argv[1])
tag = sys.argv[2]
target = sys.argv[3] if len(sys.argv) > 3 else os.environ['GITHUB_SHA']
target = subprocess.check_output(['git', 'rev-parse', target], text=True).strip()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
if target != head:
    raise SystemExit('Source commit does not match the checked-out APK build commit')
changed = subprocess.check_output(['git', 'diff', '--name-only', 'HEAD', '--'], text=True).strip()
if changed:
    raise SystemExit('Tracked source changed after checkout; commit it and rebuild before publication:\n' + changed)
apk = Path('Tink-Android-release.apk')
if source.resolve() != apk.resolve():
    shutil.copyfile(source, apk)
if apk.stat().st_size < 1_000_000:
    raise SystemExit('Refusing to publish an implausibly small APK')
metadata = Path('Tink-APK-metadata.txt')
if not metadata.is_file():
    raise SystemExit('Run verify_apk.py before publishing')
hash_value = hashlib.sha256()
with apk.open('rb') as file:
    for block in iter(lambda: file.read(1024 * 1024), b''):
        hash_value.update(block)
Path(f'{apk}.sha256').write_text(f'{hash_value.hexdigest()}  {apk.name}\n')
subprocess.run(['git', 'archive', '--format=zip', '--prefix=Tink/', 'HEAD', '-o', 'Tink-source.zip'], check=True)
with zipfile.ZipFile('Tink-source.zip') as archive:
    required = ['Tink/LICENSE', 'Tink/LICENSES/Tink-original-MIT.txt',
                'Tink/third_party/paisa_6_3_6/NOTICE.md',
                'Tink/third_party/paisa_6_3_6/SOURCE_MANIFEST.json',
                'Tink/lib/core/services/paisa_legacy_decoder.dart',
                'Tink/lib/core/services/paisa_import_service.dart']
    if not set(required).issubset(archive.namelist()):
        raise SystemExit('Corresponding source is missing compatibility code or licence notices')
version = re.search(r'^version:\s*([^+\s]+)\+(\d+)', Path('pubspec.yaml').read_text(), re.M)
if not version:
    raise SystemExit('Missing application version in pubspec.yaml')
notes = (f'Tink {version[1]} build {version[2]}. 2026 test edition preserving coffee/peach reference batches 1–4, with inline Home reordering, page shortcuts, shape privacy, keyboard flow, category exclusions, tablet account panes and safe legacy Paisa 6.3.6 import. '
         'Optimized, verified Android 7/API 24+ APK with ARM64, ARMv7 and x86-64 payloads and no Internet permission. '
         'Test/debug-key signed unless a persistent keystore was configured. Export and verify a backup before uninstalling an older differently signed build. '
         'GPL-3.0-or-later compatibility notices and exact-build corresponding runnable source are included with public certificate/checksum metadata. Not current official Paisa source or certified feature parity. See README for device QA, translation scope, design differences and platform limits.')
Path('Tink-source.zip.sha256').write_text(hashlib.sha256(Path('Tink-source.zip').read_bytes()).hexdigest() + '  Tink-source.zip\n')



def run(args):
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, end='', flush=True)
    if result.returncode and ('HTTP 403' in result.stdout or 'HTTP 401' in result.stdout):
        raise SystemExit('GitHub denied this workflow token. Check repository permissions; an authorized gh release create can reserve the release before retrying the upload. Do not add credentials to source.')
    return result.returncode == 0


for attempt in range(5):
    if run(['gh', 'release', 'view', tag]):
        break
    if run(['gh', 'release', 'create', tag, '--target', target, '--prerelease', '--title', f'Tink {version[1]}+{version[2]} — Android test build', '--notes', notes]):
        break
    time.sleep(8 * (attempt + 1))
else:
    raise SystemExit('Release creation failed after retries; diagnostics are above')

assets = [str(apk), f'{apk}.sha256', 'Tink-source.zip', 'Tink-source.zip.sha256', str(metadata)]
for attempt in range(5):
    if run(['gh', 'release', 'upload', tag, *assets, '--clobber']):
        print(f'::notice title=Tink download ready::Published {tag}; APK SHA-256 {hash_value.hexdigest()}')
        break
    time.sleep(8 * (attempt + 1))
else:
    raise SystemExit('Asset upload failed after retries; rerun is safe and keeps the same signed APK')
