import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet-control-geocoder"

export default class extends Controller {
  static targets = ["map", "latitude", "longitude"]

  connect() {
    console.log("ProjectMapController conectado ✅")

    this.initializeMap()
    this.addTileLayer()
    this.addMarker()
    this.enableGeolocation()
    this.addGeocoder()

    setTimeout(() => this.map.invalidateSize(), 0)
  }

  // --- Inicialización ---
  initializeMap() {
    const lat = parseFloat(this.latitudeTarget.value) || -32.8895 // Mendoza
    const lng = parseFloat(this.longitudeTarget.value) || -68.8458
    this.map = L.map(this.mapTarget).setView([lat, lng], 13)
  }

  addTileLayer() {
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
      detectRetina: true
    }).addTo(this.map)
  }

  // --- Marcador ---
  addMarker() {
    const lat = this.map.getCenter().lat
    const lng = this.map.getCenter().lng

    this.marker = L.marker([lat, lng], { draggable: true }).addTo(this.map)
    this.marker.on("dragend", this.updateCoordinatesFromMarker.bind(this))
  }

  updateCoordinatesFromMarker(event) {
    const { lat, lng } = event.target.getLatLng()
    this.latitudeTarget.value = lat
    this.longitudeTarget.value = lng
    console.log("📍 Marcador movido a:", lat, lng)
  }

  // --- Geolocalización ---
  enableGeolocation() {
    if (!navigator.geolocation) return

    navigator.geolocation.getCurrentPosition(
      this.setLocationFromDevice.bind(this),
      this.handleGeolocationError.bind(this)
    )
  }

  setLocationFromDevice(position) {
    const { latitude, longitude } = position.coords
    this.map.setView([latitude, longitude], 15)
    this.marker.setLatLng([latitude, longitude])
    this.latitudeTarget.value = latitude
    this.longitudeTarget.value = longitude
    console.log("📍 Ubicación detectada:", latitude, longitude)
  }

  handleGeolocationError(error) {
    console.warn("⚠️ No se pudo obtener la geolocalización:", error.message)
  }

  // --- Geocoder ---
  addGeocoder() {
    L.Control.geocoder({ defaultMarkGeocode: false })
      .on("markgeocode", this.handleGeocode.bind(this))
      .addTo(this.map)
  }

  handleGeocode(e) {
    const { center, name } = e.geocode
    this.map.setView(center, 16)
    this.marker.setLatLng(center)
    this.latitudeTarget.value = center.lat
    this.longitudeTarget.value = center.lng

    const locationInput = document.querySelector("input[name='project[location]']")
    if (locationInput) locationInput.value = name

    console.log("🔎 Dirección seleccionada:", name, center.lat, center.lng)
  }
}
