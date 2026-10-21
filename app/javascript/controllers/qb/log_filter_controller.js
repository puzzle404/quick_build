import { Controller } from "@hotwired/stimulus"

// Filtro Todo / Notas / Actividad de la bitácora del proyecto: sólo cambia
// data-filter en la lista; el CSS (.qb-log[data-filter=…]) oculta el resto.
export default class extends Controller {
  static targets = ["button", "list", "more"]

  pick(event) {
    const value = event.currentTarget.dataset.value
    this.listTarget.dataset.filter = value
    this.buttonTargets.forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.value === value)))
    // Filtrando se muestra todo lo que coincide; "Todo" vuelve al tope inicial.
    this.listTarget.dataset.expanded = value === "all" ? "false" : "true"
    if (this.hasMoreTarget) {
      this.moreTarget.hidden = value !== "all"
      this.moreTarget.textContent = this.moreTarget.dataset.label
    }
  }

  toggleMore() {
    const expanded = this.listTarget.dataset.expanded === "true"
    this.listTarget.dataset.expanded = String(!expanded)
    if (this.hasMoreTarget) this.moreTarget.textContent = expanded ? this.moreTarget.dataset.label : "Ver menos"
  }

  moreTargetConnected(el) {
    el.dataset.label = el.textContent
  }
}
