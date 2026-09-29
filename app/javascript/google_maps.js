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

// ─── Estilo de los mapas según el tema de la app ───────────────────────────
// JSON styling (sin Map ID en Google Cloud). Los colores son los tokens de QB
// OS pasados a hex (Google no acepta oklch): Night = fondo --color-bg y líneas
// --color-line; Graphite = el mismo mapa sobrio en claro. Sin negocios ni
// íconos de transporte: sólo calles, agua, parques y nombres.
const NIGHT_STYLES = [
  { elementType: "geometry", stylers: [{ color: "#161b22" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#8a94a3" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#161b22" }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "administrative", elementType: "geometry", stylers: [{ color: "#2a313b" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "poi.park", stylers: [{ visibility: "on" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#18261e" }] },
  { featureType: "poi.park", elementType: "labels.text.fill", stylers: [{ color: "#5f7a68" }] },
  { featureType: "poi.park", elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#262d37" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#1b2129" }] },
  { featureType: "road.arterial", elementType: "geometry", stylers: [{ color: "#2c343f" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#353f4c" }] },
  { featureType: "road.highway", elementType: "labels.text.fill", stylers: [{ color: "#a3adbb" }] },
  { featureType: "road.local", elementType: "labels.text.fill", stylers: [{ color: "#6b7481" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#0e1720" }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: "#4b5a6b" }] }
]

const GRAPHITE_STYLES = [
  { elementType: "geometry", stylers: [{ color: "#f4f4f1" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#6b7280" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#f4f4f1" }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "administrative", elementType: "geometry", stylers: [{ color: "#d9dadd" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "poi.park", stylers: [{ visibility: "on" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#e2eadf" }] },
  { featureType: "poi.park", elementType: "labels.text.fill", stylers: [{ color: "#7d8f7f" }] },
  { featureType: "poi.park", elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#ffffff" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#e4e5e8" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#ebecef" }] },
  { featureType: "road.local", elementType: "labels.text.fill", stylers: [{ color: "#9aa0a9" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#d6e0e8" }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: "#8795a3" }] }
]

function nightTheme() {
  return document.documentElement.dataset.theme === "night"
}

// Opciones de estilo para `new Map(el, { ...mapThemeOptions(), … })`.
// backgroundColor evita el destello blanco mientras cargan los tiles.
export function mapThemeOptions() {
  return nightTheme()
    ? { styles: NIGHT_STYLES, backgroundColor: "#161b22" }
    : { styles: GRAPHITE_STYLES, backgroundColor: "#f4f4f1" }
}

// Re-estiliza el mapa cuando el usuario cambia de tema (Tweaks). Devuelve el
// observer: el controller lo desconecta en disconnect().
export function followTheme(map) {
  const observer = new MutationObserver(() => map.setOptions({ styles: mapThemeOptions().styles }))
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] })
  return observer
}
