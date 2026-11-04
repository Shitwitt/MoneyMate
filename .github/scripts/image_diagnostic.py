"""Temporary tiny screenshot transport for API-only verification clients."""
import base64
from pathlib import Path
import sys
p = Path('web-dashboard.jpg')
if not p.exists():
    p = Path('web-failure.jpg')
if p.exists():
    text = base64.b64encode(p.read_bytes()).decode()
    offset = int(sys.argv[1]) * 10
    for index in range(offset, min(offset + 10, (len(text) + 2999) // 3000)):
        print(f'::notice title=paisa-screen-{index + 1}::{text[index * 3000:(index + 1) * 3000]}')
