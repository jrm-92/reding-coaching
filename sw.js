/* Service worker minimal — rend la page installable et disponible hors-ligne.
   Stratégie « réseau d'abord » : on récupère toujours la version à jour, et
   le cache ne sert que de secours si la connexion échoue. Les ressources
   externes (Google Sheet, météo Open-Meteo) ne sont jamais mises en cache. */
var CACHE = 'reding-sessions-v1';
var ASSETS = [
  '/sessions-collectives.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  '/logo_raccourci_orange.png',
  '/logo_running_orange.png'
];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(ASSETS); }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  // On ne gère que les GET du même domaine ; le reste passe en réseau normal.
  if (req.method !== 'GET') return;
  var sameOrigin;
  try { sameOrigin = new URL(req.url).origin === self.location.origin; } catch (err) { sameOrigin = false; }
  if (!sameOrigin) return;
  e.respondWith(
    fetch(req).then(function (res) {
      var copie = res.clone();
      caches.open(CACHE).then(function (c) { c.put(req, copie); });
      return res;
    }).catch(function () { return caches.match(req); })
  );
});
