"""Emit bounded, fictional-demo screenshot chunks for API-only verification."""
import base64
from pathlib import Path
import sys

part = int(sys.argv[1]) if len(sys.argv) > 1 else 0
p = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('web-dashboard.jpg')
prefix = sys.argv[3] if len(sys.argv) > 3 else 'tink-screen'
if not p.exists() and len(sys.argv) <= 2:
    p = Path('web-failure.jpg')
if p.exists():
    text = base64.b64encode(p.read_bytes()).decode()
    # Keep all five captures within the job's annotation budget.
    chunk_size = 3000
    offset = part * 10
    for index in range(offset, min(offset + 10, (len(text) + chunk_size - 1) // chunk_size)):
        print(f'::notice title={prefix}-{index + 1}::{text[index * chunk_size:(index + 1) * chunk_size]}')
