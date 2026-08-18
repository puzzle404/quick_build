// Registro del service worker de la PWA. El SW se sirve en /service-worker
// (ver config/routes.rb -> rails/pwa#service_worker), por lo que su scope es "/".
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").catch((error) => {
      console.error("Service worker registration failed:", error)
    })
  })
}
