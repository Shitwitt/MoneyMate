#!/usr/bin/env python3
"""Create a self-hosted offline app-shell cache, without any finance data."""
import hashlib
import json
from pathlib import Path
root = Path('build/web')
if not root.joinpath('index.html').exists():
    raise SystemExit('Run flutter build web --release --no-web-resources-cdn first')
# CanvasKit unconditionally downloads its default Roboto unless that family
# appears in FontManifest.json, even when the visible UI uses Poppins/Inter.
# Register the already-bundled Inter regular face under that engine fallback
# alias. This changes neither the font file nor the app's selected typography.
manifest_path = root / 'assets/FontManifest.json'
manifest = json.loads(manifest_path.read_text())
if not any(family['family'] == 'Roboto' for family in manifest):
    inter = next((family for family in manifest if family['family'] == 'Inter'), None)
    if inter is None:
        raise SystemExit('Bundled Inter is required for the offline renderer fallback')
    regular = next((font for font in inter['fonts'] if font.get('weight', 400) == 400 and font.get('style', 'normal') == 'normal'), None)
    if regular is None or not (root / 'assets' / regular['asset']).is_file():
        raise SystemExit('Missing bundled Inter regular font; refusing an online fallback')
    manifest.append({'family': 'Roboto', 'fonts': [regular]})
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
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
