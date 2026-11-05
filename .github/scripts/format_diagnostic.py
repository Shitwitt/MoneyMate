"""Temporary formatter-version synchronization; emits only a bounded source diff."""
import subprocess
subprocess.run(['dart', 'format', 'lib', 'test'], check=True)
patch = subprocess.check_output(['git', 'diff', '--', 'lib', 'test'], text=True)
for i in range(0, len(patch), 6000):
    chunk = patch[i:i+6000].replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print(f'::notice title=Formatter patch {i//6000+1}::{chunk}')
