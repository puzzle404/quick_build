import { Controller } from "@hotwired/stimulus"
// Mismo orden que project_map_controller: leaflet primero, siempre.
import L from "leaflet"

// Mapa de solo lectura para el rail del proyecto. Todas las interacciones están
// apagadas a propósito: el mapa vive dentro de una columna que scrollea y no
// debe robarle la rueda ni el gesto táctil al usuario. Para ver el mapa de
// verdad está el link "Ver en mapa" al lado.
export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 15 }
  }

  connect() {
    if (!Number.isFinite(this.latValue) || !Number.isFinite(this.lngValue)) return

    // Turbo puede restaurar un snapshot con los panes ya inyectados.
    this.element.replaceChildren()

    this.map = L.map(this.element, {
      zoomControl: false,
      attributionControl: false,
      dragging: false,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      touchZoom: false,
      tap: false
    }).setView([this.latValue, this.lngValue], this.zoomValue)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      detectRetina: true
    }).addTo(this.map)

    L.marker([this.latValue, this.lngValue]).addTo(this.map)

    // El rail puede tener ancho 0 en el primer frame; sin esto los tiles quedan
    // grises o mal recortados.
    setTimeout(() => this.map?.invalidateSize(), 0)
  }

  disconnect() {
    this.map?.remove()
    this.map = null
  }
}
