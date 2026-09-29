import { Controller } from "@hotwired/stimulus"

// Actualiza el gráfico de evolución del dashboard vía Turbo Frame:
// el <select> de rango (6/12 meses) navega el frame "evolution-chart"
// hacia constructors_evolution_chart_path?months=N.
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
