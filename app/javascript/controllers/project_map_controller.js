import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet-control-geocoder"   // 👈 ya lo tenés en vendor/javascript

export default class extends Controller {
  static targets = ["map", "latitude", "longitude"]

  connect() {
    console.log("ProjectMapController conectado ✅")

    const lat = parseFloat(this.latitudeTarget.value) || -32.8895 // Mendoza
    const lng = parseFloat(this.longitudeTarget.value) || -68.8458

    this.map = L.map(this.mapTarget).setView([lat, lng], 13)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    this.marker = L.marker([lat, lng], { draggable: true }).addTo(this.map)

    this.marker.on("dragend", (event) => {
      const { lat, lng } = event.target.getLatLng()
      this.latitudeTarget.value = lat
      this.longitudeTarget.value = lng
      console.log("📍 Marcador movido a:", lat, lng)
    })

    // 👇 Acá agregamos el buscador
    L.Control.geocoder({
      defaultMarkGeocode: false
    })
      .on("markgeocode", (e) => {
        const { center, name } = e.geocode

        // centrar mapa
        this.map.setView(center, 16)

        // mover marcador
        this.marker.setLatLng(center)

        // guardar coordenadas
        this.latitudeTarget.value = center.lat
        this.longitudeTarget.value = center.lng

        // actualizar campo location del form
        const locationInput = document.querySelector("input[name='project[location]']")
        if (locationInput) locationInput.value = name

        console.log("🔎 Dirección seleccionada:", name, center.lat, center.lng)
      })
      .addTo(this.map)

    setTimeout(() => this.map.invalidateSize(), 0)
  }
}
