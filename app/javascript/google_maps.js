// Carga única y lazy de Google Maps JS (Maps + Places API New). La key sale
// del <meta name="google-maps-api-key"> del layout (GOOGLE_MAPS_API_KEY): es
// una key de navegador, pública por diseño — se protege restringiéndola por
// HTTP referrer en Google Cloud, no escondiéndola.
let loading = null

export function googleMapsKey() {
  return document.querySelector('meta[name="google-maps-api-key"]')?.content?.trim() || ""
}

export function googleMapsAvailable() {
  return googleMapsKey() !== ""
}

export function loadGoogleMaps() {
  if (window.google?.maps?.importLibrary) return Promise.resolve(window.google.maps)
  if (loading) return loading

  const key = googleMapsKey()
  if (!key) return Promise.reject(new Error("Falta GOOGLE_MAPS_API_KEY"))

  loading = new Promise((resolve, reject) => {
    const callback = "__qbGoogleMapsReady"
    window[callback] = () => resolve(window.google.maps)

    const params = new URLSearchParams({
      key, v: "weekly", loading: "async", language: "es", region: "AR", callback
    })
    const script = document.createElement("script")
    script.src = `https://maps.googleapis.com/maps/api/js?${params}`
    script.async = true
    script.onerror = () => {
      loading = null
      reject(new Error("No se pudo cargar Google Maps"))
    }
    document.head.append(script)
  })
  return loading
}

// Distancia en metros entre dos {lat, lng} (haversine; alcanza para avisar
// "el pin quedó a 300 m de la dirección").
export function distanceMeters(a, b) {
  const rad = (d) => (d * Math.PI) / 180
  const dLat = rad(b.lat - a.lat)
  const dLng = rad(b.lng - a.lng)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 2 * 6371000 * Math.asin(Math.sqrt(h))
}
