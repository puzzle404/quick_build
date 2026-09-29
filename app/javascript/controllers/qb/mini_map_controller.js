import { Controller } from "@hotwired/stimulus"
import { googleMapsAvailable, loadGoogleMaps } from "google_maps"

// Mapa de solo lectura del rail del proyecto (Google Maps). Sin gestos: vive
// en una columna que scrollea y no debe robarle la rueda ni el touch. El pin
// es el overlay fijo de .qb-pin-map (la obra siempre queda al centro).
export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 15 }
  }
  static targets = ["canvas", "fallback"]

  connect() {
    if (!Number.isFinite(this.latValue) || !Number.isFinite(this.lngValue)) return
    if (!googleMapsAvailable()) return this.showFallback()

    // En un tab oculto (rail del proyecto → "Obra") el contenedor mide 0 y
    // Google dibuja un mapa vacío que no se repinta al mostrarlo: se espera a
    // que tenga tamaño real.
    if (this.canvasTarget.offsetWidth === 0) {
      this.resizeObserver = new ResizeObserver(() => {
        if (this.canvasTarget.offsetWidth === 0) return
        this.resizeObserver.disconnect()
        this.resizeObserver = null
        this.mount()
      })
      this.resizeObserver.observe(this.canvasTarget)
      return
    }
    this.mount()
  }

  async mount() {
    try {
      await loadGoogleMaps()
      const { Map } = await google.maps.importLibrary("maps")
      if (!this.element.isConnected) return

      this.map = new Map(this.canvasTarget, {
        center: { lat: this.latValue, lng: this.lngValue },
        zoom: this.zoomValue,
        disableDefaultUI: true,
        gestureHandling: "none",
        keyboardShortcuts: false,
        clickableIcons: false
      })
    } catch (error) {
      console.warn(error)
      this.showFallback()
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.map = null
  }

  showFallback() {
    if (this.hasFallbackTarget) this.fallbackTarget.hidden = false
  }
}
