import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Controlador para actualizar chart via Turbo Frame
export default class extends Controller {
    static values = {
        url: String,
        frame: { type: String, default: "evolution-chart" }
    }

    change(event) {
        const months = event.target.value
        const url = new URL(this.urlValue, window.location.origin)
        url.searchParams.set('months', months)

        // Navigate the Turbo Frame to the new URL
        const frame = document.getElementById(this.frameValue)
        if (frame) {
            frame.src = url.toString()
        }
    }
}
