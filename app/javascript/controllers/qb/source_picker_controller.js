import { Controller } from "@hotwired/stimulus"

// Picks one of N source options inside a modal/form. Updates a hidden field
// (the `value` target) and visually highlights the chosen button.
export default class extends Controller {
  static targets = ["value"]

  pick(event) {
    const key = event.params.key
    if (this.hasValueTarget) this.valueTarget.value = key

    this.element.querySelectorAll("[data-qb-source-picker-button]").forEach(btn => {
      const active = btn.dataset.qbSourceKey === key
      btn.style.background    = active ? "color-mix(in oklab, var(--color-accent) 10%, transparent)" : "var(--color-bg-raised)"
      btn.style.borderColor   = active ? "var(--color-accent)" : "var(--color-line)"
      btn.style.color         = active ? "var(--color-accent)" : "var(--color-ink)"
    })
  }
}
