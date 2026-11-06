#!/usr/bin/env python3
"""Retry only transient dependency-service failures, never ordinary build errors."""
import os
import re
import subprocess
import sys
import time

if len(sys.argv) < 2:
    raise SystemExit('Usage: retry_build.py <command> [arguments...]')
transient = re.compile(
    r'(?:status code|HTTP(?:/[\d.]+)?)\s*[:=]?\s*(?:429|502|503|504)\b'
    r'|Too Many Requests|Connection reset|Read timed out|Temporary failure in name resolution',
    re.I,
)
for attempt in range(1, 4):
    tail = ''
    with subprocess.Popen(sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True, encoding='utf-8', errors='replace') as process:
        for line in process.stdout:
            print(line, end='', flush=True)
            tail = (tail + line)[-300_000:]
        code = process.wait()
    if code == 0:
        raise SystemExit(0)
    if attempt == 3 or not transient.search(tail):
        raise SystemExit(code)
    # Bounded backoff. The zero-delay override is used by local unit tests only.
    delay = min(120, max(0, float(os.environ.get('TINK_BUILD_RETRY_DELAY_SECONDS', '15')))) * attempt
    print(f'Transient dependency download failure; retry {attempt + 1}/3 in {delay:g}s.', flush=True)
    time.sleep(delay)
