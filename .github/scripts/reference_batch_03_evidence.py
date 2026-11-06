"""Review only fictional screenshots produced by the same web smoke run."""
from pathlib import Path
import subprocess
import sys

GROUPS = {
    'loans': ['loan-help', 'loan-help-bottom', 'loan-detail', 'loan-history',
              'loan-editor', 'loan-colors', 'loan-borrowing', 'transaction-detail'],
    'goals': ['goals-help', 'goals', 'goal-detail', 'goal-editor', 'goal-colors'],
    'labels': ['labels-help', 'labels', 'labels-grid', 'label-detail'],
    'analytics': ['analytics', 'analytics-swiped', 'analytics-monthly', 'analytics-predictions',
                  'analytics-unusual', 'analytics-trends', 'analytics-weekdays',
                  'analytics-methods'],
}
for name in GROUPS[sys.argv[1]]:
    frame = Path(f'review-shots/web-batch3-{name}.jpg')
    thumbnail = frame.with_name(frame.stem + '-thumb.jpg')
    for required in (frame, thumbnail):
        assert required.is_file(), f'Missing required frame: {required}'
        content = required.read_bytes()
        assert content.startswith(b'\xff\xd8') and content.endswith(b'\xff\xd9'), required
    assert thumbnail.stat().st_size <= 6750, 'Thumbnail exceeds annotation budget'
    subprocess.run([sys.executable, '.github/scripts/image_diagnostic.py', '0',
                    str(frame), f'batch3-{name}'], check=True)
print(f'::notice title=Batch 3 {sys.argv[1]} evidence::PASS: all {len(GROUPS[sys.argv[1]])} full frames and bounded thumbnails present. No native build.')
