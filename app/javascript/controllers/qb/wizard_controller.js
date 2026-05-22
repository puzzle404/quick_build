import { Controller } from "@hotwired/stimulus"

// Multi-step wizard with client-side navigation. Each step is a div with
// data-qb--wizard-target="step" data-step="1|2|3". The step indicators carry
// data-qb--wizard-target="indicator" data-step="N".
//
// Buttons:
//   data-action="click->qb--wizard#next"
//   data-action="click->qb--wizard#prev"
//   data-action="click->qb--wizard#goto" data-qb--wizard-step-param="N"
export default class extends Controller {
  static targets  = ["step", "indicator", "prevBtn", "nextBtn", "submitBtn"]
  static values   = { current: { type: Number, default: 1 } }

  connect() { this._render() }

  next() { this.currentValue = Math.min(this.currentValue + 1, this.stepTargets.length); this._render() }
  prev() { this.currentValue = Math.max(this.currentValue - 1, 1); this._render() }
  goto(event) {
    const n = Number(event.params.step)
    if (!isNaN(n)) { this.currentValue = n; this._render() }
  }

  _render() {
    this.stepTargets.forEach(el => {
      el.style.display = (Number(el.dataset.step) === this.currentValue ? "" : "none")
    })
    this.indicatorTargets.forEach(el => {
      const n = Number(el.dataset.step)
      const active = n === this.currentValue
      const done = n < this.currentValue
      const dot = el.querySelector("[data-qb-wizard-dot]")
      const label = el.querySelector("[data-qb-wizard-label]")
      if (dot) {
        dot.style.background = done ? "var(--color-ok)" : (active ? "var(--color-accent)" : "var(--color-line)")
        dot.style.color      = (done || active) ? "white" : "var(--color-ink-3)"
        dot.textContent      = done ? "✓" : String(n)
      }
      if (label) {
        label.style.color      = active ? "var(--color-ink)" : "var(--color-ink-3)"
        label.style.fontWeight = active ? 600 : 500
      }
      el.style.background = active ? "var(--color-bg-sunken)" : "transparent"
    })
    if (this.hasPrevBtnTarget) this.prevBtnTarget.style.display = this.currentValue > 1 ? "" : "none"
    if (this.hasNextBtnTarget) this.nextBtnTarget.style.display = this.currentValue < this.stepTargets.length ? "" : "none"
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.style.display = this.currentValue === this.stepTargets.length ? "" : "none"
  }
}
