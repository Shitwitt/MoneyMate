#!/usr/bin/env python3
"""Keep normal build logs, and expose bounded failure details in check annotations.

This also helps clients whose network policy permits api.github.com but not
GitHub's separate Actions log-storage host. No credentials or finance files are
read; only stdout/stderr from the explicitly supplied build/check command.
"""
import collections
import re
import subprocess
import sys

if len(sys.argv) < 2:
    raise SystemExit('Usage: checked_command.py <command> [args...]')
lines = collections.deque(maxlen=1500)
with subprocess.Popen(sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                      text=True, encoding='utf-8', errors='replace') as process:
    for line in process.stdout:
        print(line, end='', flush=True)
        lines.append(line)
    code = process.wait()
if code:
    selected = []
    for line in lines:
        if line.lstrip().startswith('info •'):
            continue
        frame = re.match(r'^\s*#(\d+)\s', line)
        if frame and int(frame[1]) > 12 and 'file://' not in line and 'package:paisaclone/' not in line:
            continue
        if line.lstrip().startswith(('at org.gradle.', 'at java.', 'at jdk.')):
            continue
        selected.append(line)
    text = ''.join(selected)[-27000:]
    for index in range(0, len(text), 3000):
        chunk = text[index:index + 3000].replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
        print(f'::error title=Build diagnostics {index // 3000 + 1}::{chunk}', flush=True)
raise SystemExit(code)
