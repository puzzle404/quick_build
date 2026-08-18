import { Controller } from "@hotwired/stimulus"
// El orden importa: leaflet-control-geocoder es UMD y lee globalThis.L, que
// solo existe porque el bundle de leaflet lo setea al evaluarse. Si se invierten
// estos dos imports, el geocoder explota con TypeError.
import L from "leaflet"
import "leaflet-control-geocoder"

const DEFAULT_CENTER = [-32.8895, -68.8458] // Mendoza
const DEFAULT_ZOOM = 13
const LOCATED_ZOOM = 16

// Sesgo suave hacia Argentina: Nominatim prioriza lo que cae dentro del
// viewbox pero (con bounded=0) sigue devolviendo obras fuera del país.
const AR_VIEWBOX = "-73.6,-21.8,-53.6,-55.1"

// Nominatim pide como máximo 1 request/segundo. El control de búsqueda ya
// debouncea solo (suggestTimeout); el reverse del marcador lo debounceamos acá
// para no disparar un request por cada micro-arrastre.
const REVERSE_DEBOUNCE_MS = 800

export default class extends Controller {
  static targets = [
    "map",
    "latitude",
    "longitude",
    "location",
    "suggestion",
    "suggestionAddress"
  ]

  connect() {
    // Se lee ANTES de tocar nada: define si la obra ya estaba georreferenciada.
    const alreadyLocated = this.hasSavedCoordinates

    this.initializeMap()
    this.addTileLayer()
    this.addMarker()
    this.addGeocoder()

    // Solo pedimos la ubicación del dispositivo cuando la obra todavía no tiene
    // coordenadas (alta nueva). Antes corría siempre y al abrir /edit desde otra
    // ciudad reubicaba la obra en donde estaba parado quien editaba.
    if (!alreadyLocated) this.enableGeolocation()

    setTimeout(() => this.map?.invalidateSize(), 0)
  }

  disconnect() {
    clearTimeout(this.reverseTimeout)
    this.reverseTimeout = null
    this.map?.remove()
    this.map = null
    this.marker = null
  }

  // --- Inicialización ---
  initializeMap() {
    // Turbo puede restaurar un snapshot que ya tiene los panes que Leaflet
    // inyectó. Los sacamos para no montar el mapa nuevo encima de los restos
    // del anterior. Ojo: se borran SOLO los nodos de Leaflet, porque en el
    // wizard de alta los hidden lat/lng viven dentro de este contenedor.
    this.mapTarget
      .querySelectorAll(":scope > .leaflet-pane, :scope > .leaflet-control-container")
      .forEach((node) => node.remove())

    const center = this.savedLatLng
    this.map = L.map(this.mapTarget).setView(
      center || DEFAULT_CENTER,
      center ? LOCATED_ZOOM : DEFAULT_ZOOM
    )
  }

  addTileLayer() {
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19,
      detectRetina: true
    }).addTo(this.map)
  }

  // --- Marcador ---
  addMarker() {
    this.marker = L.marker(this.map.getCenter(), { draggable: true }).addTo(this.map)
    this.marker.on("dragend", this.updateCoordinatesFromMarker.bind(this))
  }

  updateCoordinatesFromMarker(event) {
    const latlng = event.target.getLatLng()
    this.writeCoordinates(latlng)
    this.scheduleReverseGeocode(latlng)
  }

  // --- Geolocalización ---
  enableGeolocation() {
    if (!navigator.geolocation) return

    navigator.geolocation.getCurrentPosition(
      this.setLocationFromDevice.bind(this),
      this.handleGeolocationError.bind(this)
    )
  }

  // Acá NO hacemos reverse geocoding a propósito: la posición que reporta el
  // navegador suele ser la del proveedor de internet y puede estar a kilómetros.
  // Sirve para centrar el mapa, no para escribir un domicilio que después queda
  // guardado como si alguien lo hubiera verificado.
  setLocationFromDevice(position) {
    if (!this.map) return // la respuesta puede llegar después de navegar

    const { latitude, longitude } = position.coords
    this.map.setView([latitude, longitude], LOCATED_ZOOM)
    this.marker.setLatLng([latitude, longitude])
    this.writeCoordinates({ lat: latitude, lng: longitude })
  }

  handleGeolocationError(error) {
    console.warn("No se pudo obtener la geolocalización:", error.message)
  }

  // --- Buscador de direcciones ---
  addGeocoder() {
    // geocodingQueryParams lo usa la búsqueda; reverseQueryParams, el reverse
    // del marcador. Son dos bolsas distintas: si el idioma va sólo en la
    // primera, las direcciones del marcador vuelven en inglés.
    this.searchGeocoder = L.Control.Geocoder.nominatim({
      geocodingQueryParams: {
        "accept-language": "es",
        viewbox: AR_VIEWBOX,
        bounded: 0
      },
      reverseQueryParams: {
        "accept-language": "es"
      }
    })

    // El control sólo engancha el listener de "input" (o sea, sugerir mientras
    // se escribe) si el geocoder implementa suggest(), y la clase Nominatim del
    // vendor no lo implementa: define geocode() y reverse() nada más. Sin esto
    // hay que apretar Enter para buscar. El resto de los geocoders del paquete
    // resuelven suggest delegando en geocode, así que hacemos lo mismo.
    // El control debouncea (suggestTimeout) y descarta respuestas viejas por su
    // cuenta, así que no se le pega a Nominatim en cada tecla.
    this.searchGeocoder.suggest = (query, context) => this.searchGeocoder.geocode(query, context)

    L.Control.geocoder({
      geocoder: this.searchGeocoder,
      defaultMarkGeocode: false,
      collapsed: false,
      position: "topright",
      placeholder: "Buscá una dirección…",
      errorMessage: "No encontramos esa dirección",
      iconLabel: "Buscar dirección",
      queryMinLength: 3,
      suggestMinLength: 4,
      suggestTimeout: 700
    })
      .on("markgeocode", this.handleGeocode.bind(this))
      .addTo(this.map)
  }

  // Elegir un resultado del buscador es una acción explícita: acá SÍ pisamos el
  // domicilio, porque es exactamente lo que el usuario pidió.
  handleGeocode(event) {
    const { center, name } = event.geocode

    this.map.setView(center, LOCATED_ZOOM)
    this.marker.setLatLng(center)
    this.writeCoordinates(center)

    clearTimeout(this.reverseTimeout)
    this.reverseToken = (this.reverseToken || 0) + 1

    const input = this.locationInput
    if (input && name) input.value = name
    this.hideSuggestion()
  }

  // --- Reverse geocoding (arrastrar el marcador completa la dirección) ---
  scheduleReverseGeocode(latlng) {
    clearTimeout(this.reverseTimeout)
    const token = (this.reverseToken || 0) + 1
    this.reverseToken = token
    this.reverseTimeout = setTimeout(() => this.reverseGeocode(latlng, token), REVERSE_DEBOUNCE_MS)
  }

  async reverseGeocode(latlng, token) {
    if (!this.map || !this.searchGeocoder) return

    const scale = this.map.options.crs.scale(this.map.getZoom())
    let results = []

    try {
      results = await this.searchGeocoder.reverse(latlng, scale)
    } catch (error) {
      console.warn("No se pudo resolver la dirección del marcador:", error)
      return
    }

    // Llegó tarde: el usuario movió el marcador otra vez o se fue de la página.
    if (token !== this.reverseToken || !this.map) return

    const address = results?.[0]?.name
    const input = this.locationInput
    if (!address || !input) return

    const current = input.value.trim()

    if (current === "") {
      // Campo vacío: completamos directo, no hay nada que perder.
      input.value = address
      this.hideSuggestion()
    } else if (current === address) {
      this.hideSuggestion()
    } else {
      // Ya hay un domicilio escrito a mano (ej. "Obrador km 3, s/n"): no lo
      // pisamos en silencio, lo ofrecemos y que decida el usuario.
      this.showSuggestion(address)
    }
  }

  // --- Chip "Usar esta dirección" ---
  showSuggestion(address) {
    this.pendingAddress = address
    if (!this.hasSuggestionTarget) return

    if (this.hasSuggestionAddressTarget) this.suggestionAddressTarget.textContent = address
    this.suggestionTarget.style.display = "flex"
  }

  hideSuggestion() {
    this.pendingAddress = null
    if (!this.hasSuggestionTarget) return

    this.suggestionTarget.style.display = "none"
  }

  acceptSuggestion(event) {
    event?.preventDefault()

    const input = this.locationInput
    if (input && this.pendingAddress) input.value = this.pendingAddress
    this.hideSuggestion()
  }

  dismissSuggestion(event) {
    event?.preventDefault()
    this.hideSuggestion()
  }

  // --- Helpers ---
  writeCoordinates({ lat, lng }) {
    this.latitudeTarget.value = lat
    this.longitudeTarget.value = lng
  }

  get locationInput() {
    if (this.hasLocationTarget) return this.locationTarget

    // Fallback para el wizard de alta, donde el input Domicilio todavía vive
    // fuera del elemento del controller y no puede ser target.
    return document.querySelector("input[name='project[location]']")
  }

  get savedLatLng() {
    const lat = this.parseCoordinate(this.latitudeTarget.value)
    const lng = this.parseCoordinate(this.longitudeTarget.value)
    return lat === null || lng === null ? null : [lat, lng]
  }

  get hasSavedCoordinates() {
    return this.savedLatLng !== null
  }

  // parseFloat("0") es 0, que es falsy: hay que chequear con Number.isFinite y
  // no con `||`, o una coordenada 0 se trataría como "sin dato".
  parseCoordinate(value) {
    const parsed = parseFloat(value)
    return Number.isFinite(parsed) ? parsed : null
  }
}
