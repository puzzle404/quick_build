// QuickBuild — service worker mínimo.
// Objetivo: cumplir el criterio de "installable" (manifest + SW con fetch
// handler) y servir una página offline cuando una navegación falla.
// No cachea datos de la app (sin offline elaborado, a propósito).

const CACHE = "qb-shell-v2";
const OFFLINE_URL = "/offline.html";
const PRECACHE = [OFFLINE_URL, "/icon-192.png", "/icon-512.png"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      // cache: "reload" saltea el cache HTTP del navegador para que el
      // precache guarde copias frescas del servidor, no una versión vieja.
      .then((cache) =>
        cache.addAll(PRECACHE.map((url) => new Request(url, { cache: "reload" })))
      )
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
      )
      .then(() => self.clients.claim())
  );
});

// Respuesta de emergencia si el cache fue purgado y tampoco hay red.
function offlineFallbackResponse() {
  return new Response(
    '<!DOCTYPE html><html lang="es"><meta charset="utf-8">' +
      "<title>Sin conexión</title><p>Sin conexión. Reintentá cuando vuelvas a tener señal.</p>",
    { status: 503, headers: { "Content-Type": "text/html; charset=utf-8" } }
  );
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Cache-first para los assets precacheados (página offline e íconos):
  // así offline.html puede cargar su ícono aun sin red.
  if (url.origin === self.location.origin && PRECACHE.includes(url.pathname)) {
    event.respondWith(
      caches.match(url.pathname).then((cached) => cached || fetch(request))
    );
    return;
  }

  // Network-first para navegaciones; si no hay red, cae a la página offline.
  // caches.match puede resolver undefined (cache purgado): garantizamos
  // devolver siempre una Response.
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(() =>
        caches
          .match(OFFLINE_URL)
          .then((cached) => cached || offlineFallbackResponse())
      )
    );
  }
});
