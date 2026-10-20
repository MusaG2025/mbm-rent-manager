/* MBM V14 cache-retirement worker.
   Replaces the earlier offline-first worker that could keep old screens alive.
   Once installed it clears MBM caches and unregisters itself. */
self.addEventListener('install', event => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => /^mbm-|rentapp/i.test(key)).map(key => caches.delete(key)));
    await self.registration.unregister();
    await self.clients.claim();
  })());
});
