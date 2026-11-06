"""Require and expose 2026 frames from the same fictional real-browser run."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

FRAMES = ['home-reorder', 'home-reordered', 'privacy', 'shortcuts', 'filters',
          'entry-next', 'portrait-accounts', 'landscape-accounts', 'import-file',
          'import-preview', 'import-notes', 'import-saved']
part = sys.argv[1] if len(sys.argv) > 1 else '--verify-only'
selected = [] if part == '--verify-only' else FRAMES[int(part) * 3:(int(part) + 1) * 3]
manifest = []
for name in FRAMES:
    frame = Path(f'review-shots/web-2026-{name}.jpg')
    thumb = frame.with_name(frame.stem + '-thumb.jpg')
    record = {'name': name}
    for kind, required in [('full', frame), ('review', thumb)]:
        assert required.is_file(), f'Missing 2026 evidence: {required}'
        data = required.read_bytes()
        assert data.startswith(b'\xff\xd8') and data.endswith(b'\xff\xd9'), required
        record[kind] = {'filename': required.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
    assert thumb.stat().st_size <= 6750, 'Review thumbnail exceeds annotation budget'
    manifest.append(record)
    if name in selected:
        subprocess.run([sys.executable, '.github/scripts/image_diagnostic.py', '0', str(frame), f'2026-{name}'], check=True)
if part == '--verify-only':
    print('::notice title=2026 evidence manifest::' + json.dumps(manifest, separators=(',', ':')))
else:
    print(f'2026 evidence part {part}: {len(selected)} bounded review images. Full frames remain in the same run artifact.')
