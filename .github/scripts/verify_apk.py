#!/usr/bin/env python3
"""Verify release version, Tink label, native ABIs, signing and offline permission."""
from pathlib import Path
import hashlib
import os
import re
import subprocess
import sys
import zipfile

apk = Path(sys.argv[1])
version = re.search(r'^version:\s*([\d.]+)\+(\d+)', Path('pubspec.yaml').read_text(), re.M)
if not version:
    raise SystemExit('pubspec.yaml needs an explicit version name and build number')
sdk = Path(os.environ['ANDROID_HOME'])
tools = sorted(sdk.glob('build-tools/*/aapt'), key=lambda p: [int(x) for x in re.findall(r'\d+', p.parent.name)])
if not tools:
    raise SystemExit('Android SDK aapt not found')
aapt = tools[-1]
badging = subprocess.check_output([str(aapt), 'dump', 'badging', str(apk)], text=True)
permissions = subprocess.check_output([str(aapt), 'dump', 'permissions', str(apk)], text=True)
for expected in ["name='com.example.paisaclone'", f"versionCode='{version[2]}'", f"versionName='{version[1]}'", "application-label:'Tink'", "sdkVersion:'24'"]:
    if expected not in badging:
        raise SystemExit(f'Unexpected APK metadata: missing {expected}')
if 'android.permission.INTERNET' in permissions:
    raise SystemExit('Offline release must not request Internet permission')
with zipfile.ZipFile(apk) as archive:
    for name in ['GPL-3.0-or-later.txt', 'Tink-original-MIT.txt', 'Paisa-compatibility-NOTICE.txt']:
        source_notice = Path('assets/licenses') / name
        bundled_notice = 'assets/flutter_assets/assets/licenses/' + name
        if hashlib.sha256(archive.read(bundled_notice)).digest() != hashlib.sha256(source_notice.read_bytes()).digest():
            raise SystemExit(f'Missing or mismatched bundled source/licence notice: {name}')
    abis = sorted({name.split('/')[1] for name in archive.namelist() if name.endswith('/libapp.so')})
    required_abis = {'arm64-v8a', 'armeabi-v7a', 'x86_64'}
    if not required_abis.issubset(abis):
        raise SystemExit(f'Missing Flutter native payloads: {sorted(required_abis - set(abis))}')
signer = aapt.parent/'apksigner'
cert = subprocess.check_output([str(signer), 'verify', '--print-certs', str(apk)], text=True)
report = '\n'.join([f'Tink {version[1]}+{version[2]}', f'APK size: {apk.stat().st_size:,} bytes', f'Native ABIs: {", ".join(abis)}', 'No Internet permission: verified', 'GPL-3.0-or-later / original MIT / modification notices: verified in APK', 'Android minimum: API 24 (Android 7)', '', badging.splitlines()[0], cert])
Path('Tink-APK-metadata.txt').write_text(report)
print(report)
escaped = report.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
print(f'::notice title=Tink APK verified::{escaped}')
