"""Temporary formatter-version synchronization; emits only a bounded source diff."""
import base64
import subprocess
subprocess.run(['dart', 'format', 'lib', 'test'], check=True)
patch = subprocess.check_output(['git', 'diff', '--', 'lib', 'test'])
encoded = base64.b64encode(patch).decode()
for i in range(0, len(encoded), 2500):
    print(f'::notice title=Formatter base64 {i//2500+1}::{encoded[i:i+2500]}')
