#!/usr/bin/env python3
"""Create a self-hosted offline app-shell cache, without any finance data."""
import hashlib
import json
from pathlib import Path
root = Path('build/web')
if not root.joinpath('index.html').exists():
    raise SystemExit('Run flutter build web --release --no-web-resources-cdn first')
files = sorted(p for p in root.rglob('*') if p.is_file() and p.name not in {'service-worker.js', 'flutter_service_worker.js'} and not p.name.endswith('.map'))
revision = hashlib.sha256(b''.join(hashlib.sha256(p.read_bytes()).digest() for p in files)).hexdigest()[:16]
urls = ['./' + p.relative_to(root).as_posix() for p in files]
worker = r"""
const CACHE = 'tink-REVISION';
const FILES = URLS;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => (key.startsWith('tink-') || key.startsWith('paisaclone-')) && key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if(event.request.method !== 'GET' || url.origin !== self.location.origin) return;
  event.respondWith(caches.open(CACHE).then(async cache => {
    const found = await cache.match(event.request, {ignoreSearch: true});
    if(found) return found;
    try { return await fetch(event.request); }
    catch(error) { if(event.request.mode === 'navigate') return cache.match('./index.html'); throw error; }
  }));
});
""".replace('REVISION', revision).replace('URLS', json.dumps(urls))
root.joinpath('service-worker.js').write_text(worker)
print(f'Offline cache {revision}: {len(files)} local app files; no financial data is cached by this worker.')
