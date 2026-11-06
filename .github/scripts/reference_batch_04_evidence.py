"""Require and expose only fictional Batch 4 frames from the same browser run."""
from pathlib import Path
import subprocess
import sys

GROUPS = {
    'recurring': ['recurring', 'recurring-calendar', 'recurring-help', 'recurring-help-bottom'],
    'catalog': ['categories', 'categories-help', 'category-breakdown', 'category-donut',
                'category-monthly', 'category-hold', 'category-weekly', 'category-overview', 'category-insights'],
    'entry': ['transaction-main', 'transaction-calculator', 'transaction-links',
              'transaction-context', 'transaction-collapsed', 'transaction-saved'],
    'context': ['places', 'places-grid', 'places-help', 'place-detail',
                'people', 'people-help', 'person-detail'],
    'health': ['health-index', 'health-streak', 'health-challenge', 'health-report',
               'health-habits', 'health-habits-swiped', 'health-heatmap', 'health-hold',
               'health-categories', 'health-projection', 'health-repeats',
               'health-reminder-draft', 'health-methods'],
}
frames = GROUPS[sys.argv[1]]
part = sys.argv[2] if len(sys.argv) > 2 else '0'
# Ten notices/step and fifty/job: at most three bounded images per step.
selected = [] if part == '--verify-only' else frames[int(part)*3:(int(part)+1)*3]
for name in frames:
    full = Path(f'review-shots/web-batch4-{name}.jpg')
    thumb = full.with_name(full.stem + '-thumb.jpg')
    for required in (full, thumb):
        assert required.is_file(), f'Missing required Batch 4 frame: {required}'
        image = required.read_bytes()
        assert image.startswith(b'\xff\xd8') and image.endswith(b'\xff\xd9'), required
    assert thumb.stat().st_size <= 6750, 'Review copy exceeds annotation budget'
    if name in selected:
        subprocess.run([sys.executable, '.github/scripts/image_diagnostic.py', '0',
                        str(full), f'batch4-{name}'], check=True)
print(f'::notice title=Batch 4 {sys.argv[1]} evidence::PASS: all {len(frames)} full frames and bounded review copies present. No native build.')
