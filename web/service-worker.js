// The post-build script replaces this with a content-addressed offline cache.
// Development / plain flutter build still work without an installed cache.
self.addEventListener('fetch', () => {});
