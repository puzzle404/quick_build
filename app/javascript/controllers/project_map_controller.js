import { Controller } from "@hotwired/stimulus"
import { googleMapsAvailable, loadGoogleMaps, distanceMeters, mapThemeOptions, followTheme } from "google_maps"

// Dirección + ubicación de la obra, al estilo PedidosYa / Airbnb:
//   1. Un solo campo "Dirección": mientras se escribe aparecen sugerencias de
//      Google (Places API New) debajo del campo.
//   2. Elegir una sugerencia completa la dirección y centra el mapa ahí, con un
//      pin FIJO en el medio: se mueve el mapa (no el pin) para ajustar el punto
//      exacto de la obra. Mover el mapa nunca cambia la dirección.
//   3. Si el pin termina lejos de la dirección elegida se avisa; al compartir
//      manda la dirección.
// Sin GOOGLE_MAPS_API_KEY el campo funciona como texto libre y el mapa avisa
// que falta configurarlo.
const DEFAULT_CENTER = { lat: -34.6037, lng: -58.3816 } // CABA
const LOCATED_ZOOM = 17
const SUGGEST_DEBOUNCE_MS = 250
const FAR_FROM_ADDRESS_M = 150

export default class extends Controller {
  static targets = [
    "input", "suggestions", "mapWrap", "map", "latitude", "longitude",
    "hint", "unavailable", "manualButton"
  ]

  connect() {
    this.suggestionsList = []
    this.activeIndex = -1
    this.anchor = null // punto de la dirección elegida

    if (!googleMapsAvailable()) {
      this.unavailableTarget.hidden = false
      if (this.hasManualButtonTarget) this.manualButtonTarget.hidden = true
      return
    }
    if (this.savedLatLng) this.showMap(this.savedLatLng)
  }

  disconnect() {
    clearTimeout(this.suggestTimer)
    clearTimeout(this.searchingTimer)
    this.idleListener?.remove()
    this.themeObserver?.disconnect()
    this.map = null
  }

  // --- Autocomplete ---
  query() {
    clearTimeout(this.suggestTimer)
    const text = this.inputTarget.value.trim()
    if (!googleMapsAvailable() || text.length < 3) return this.closeSuggestions()

    this.suggestTimer = setTimeout(() => this.fetchSuggestions(text), SUGGEST_DEBOUNCE_MS)
  }

  async fetchSuggestions(text) {
    // Respuesta lenta: "Buscando direcciones…" con el anillo en la lista.
    clearTimeout(this.searchingTimer)
    this.searchingTimer = setTimeout(() => this.showSearching(), 300)
    try {
      const places = await this.places()
      this.sessionToken ||= new places.AutocompleteSessionToken()
      const request = {
        input: text,
        sessionToken: this.sessionToken,
        includedRegionCodes: ["ar"],
        language: "es",
        region: "ar"
      }
      if (this.map) request.origin = this.map.getCenter()

      const { suggestions } = await places.AutocompleteSuggestion.fetchAutocompleteSuggestions(request)
      clearTimeout(this.searchingTimer)
      // Llegó tarde: el usuario siguió escribiendo.
      if (text !== this.inputTarget.value.trim()) return
      this.renderSuggestions(suggestions.map((s) => s.placePrediction).filter(Boolean))
    } catch (error) {
      clearTimeout(this.searchingTimer)
      console.warn("No se pudieron buscar direcciones:", error)
      this.closeSuggestions()
    }
  }

  renderSuggestions(predictions) {
    this.suggestionsList = predictions
    this.activeIndex = -1
    const list = this.suggestionsTarget
    list.replaceChildren()
    if (predictions.length === 0) return this.closeSuggestions()

    predictions.forEach((prediction, index) => {
      const item = document.createElement("li")
      item.setAttribute("role", "option")
      item.id = `${this.inputTarget.id}-opt-${index}`
      item.className = "qb-addr-option"
      item.dataset.index = index
      item.dataset.action = "mousedown->project-map#pick"

      const main = document.createElement("span")
      main.className = "qb-addr-option-main"
      main.textContent = prediction.mainText?.toString() || prediction.text.toString()
      const secondary = document.createElement("span")
      secondary.className = "qb-addr-option-secondary"
      secondary.textContent = prediction.secondaryText?.toString() || ""
      item.append(main, secondary)
      list.append(item)
    })

    const credit = document.createElement("li")
    credit.className = "qb-addr-credit"
    credit.setAttribute("aria-hidden", "true")
    credit.textContent = "Sugerencias de Google"
    list.append(credit)

    list.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  showSearching() {
    const item = document.createElement("li")
    item.className = "qb-addr-searching"
    const ring = document.createElement("span")
    ring.className = "qb-spinner-ring"
    ring.style.setProperty("--qb-spinner-size", "12px")
    ring.style.setProperty("--qb-spinner-stroke", "1.5px")
    item.append(ring, document.createTextNode("Buscando direcciones…"))
    this.suggestionsTarget.replaceChildren(item)
    this.suggestionsTarget.hidden = false
  }

  closeSuggestions() {
    clearTimeout(this.searchingTimer)
    if (!this.hasSuggestionsTarget) return
    this.suggestionsTarget.hidden = true
    this.suggestionsTarget.replaceChildren()
    this.suggestionsList = []
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  keydown(event) {
    if (this.suggestionsTarget.hidden) return
    const count = this.suggestionsList.length

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      this.activeIndex = (this.activeIndex + step + count) % count
      this.highlight()
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      // Enter elige la sugerencia en vez de mandar el form.
      event.preventDefault()
      this.choose(this.suggestionsList[this.activeIndex])
    } else if (event.key === "Escape") {
      this.closeSuggestions()
    }
  }

  highlight() {
    this.suggestionsTarget.querySelectorAll(".qb-addr-option").forEach((el, i) => {
      el.classList.toggle("is-active", i === this.activeIndex)
      if (i === this.activeIndex) this.inputTarget.setAttribute("aria-activedescendant", el.id)
    })
  }

  // mousedown (no click): el blur del input cierra la lista antes que el click.
  pick(event) {
    event.preventDefault()
    const index = Number(event.currentTarget.dataset.index)
    this.choose(this.suggestionsList[index])
  }

  blur() {
    setTimeout(() => this.closeSuggestions(), 150)
  }

  async choose(prediction) {
    if (!prediction) return
    this.closeSuggestions()
    this.inputTarget.value = prediction.text.toString()

    try {
      const place = prediction.toPlace()
      await place.fetchFields({ fields: ["formattedAddress", "location"] })
      // Termina la sesión de autocomplete (así Google la cobra como una sola).
      this.sessionToken = null

      if (place.formattedAddress) this.inputTarget.value = place.formattedAddress
      if (place.location) {
        const point = { lat: place.location.lat(), lng: place.location.lng() }
        this.anchor = point
        await this.showMap(point, { zoom: LOCATED_ZOOM })
      }
    } catch (error) {
      console.warn("No se pudo obtener la ubicación de la dirección:", error)
    }
  }

  // "¿No encontrás la dirección? Marcala en el mapa" (lotes, rutas, obradores).
  async manual(event) {
    event?.preventDefault()
    this.anchor = null
    this.hintTarget.hidden = true
    await this.showMap(this.savedLatLng || DEFAULT_CENTER, { zoom: this.savedLatLng ? LOCATED_ZOOM : 12 })
  }

  // --- Mapa con pin fijo al centro ---
  async showMap(point, { zoom = LOCATED_ZOOM } = {}) {
    this.mapWrapTarget.hidden = false
    let maps
    try {
      maps = await this.mapsLibrary()
    } catch (error) {
      console.warn(error)
      this.unavailableTarget.hidden = false
      this.mapWrapTarget.hidden = true
      return
    }
    if (!this.element.isConnected) return

    if (!this.map) {
      this.map = new maps.Map(this.mapTarget, {
        ...mapThemeOptions(),
        center: point,
        zoom,
        disableDefaultUI: true,
        zoomControl: true,
        clickableIcons: false,
        gestureHandling: "greedy"
      })
      this.idleListener = this.map.addListener("idle", () => this.syncFromMap())
      this.themeObserver = followTheme(this.map)
    } else {
      this.map.setCenter(point)
      this.map.setZoom(zoom)
    }
    this.writeCoordinates(point)
    this.updateHint(point)
  }

  syncFromMap() {
    const center = this.map?.getCenter()
    if (!center) return
    const point = { lat: center.lat(), lng: center.lng() }
    this.writeCoordinates(point)
    this.updateHint(point)
  }

  updateHint(point) {
    if (!this.anchor) return
    const meters = distanceMeters(this.anchor, point)
    if (meters > FAR_FROM_ADDRESS_M) {
      const label = meters >= 1000 ? `${(meters / 1000).toFixed(1).replace(".", ",")} km` : `${Math.round(meters)} m`
      this.hintTarget.textContent = `El pin quedó a ${label} de la dirección. Está bien si la obra está ahí: al compartir se usa la dirección escrita.`
      this.hintTarget.hidden = false
    } else {
      this.hintTarget.hidden = true
    }
  }

  // --- Helpers ---
  async places() {
    await loadGoogleMaps()
    return google.maps.importLibrary("places")
  }

  async mapsLibrary() {
    await loadGoogleMaps()
    return google.maps.importLibrary("maps")
  }

  writeCoordinates({ lat, lng }) {
    this.latitudeTarget.value = lat.toFixed(7)
    this.longitudeTarget.value = lng.toFixed(7)
  }

  get savedLatLng() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null
  }
}
