import { Controller } from "@hotwired/stimulus"

// Collapses/expands a body element. The trigger toggles aria-expanded and
// flips the chevron via the qb-expanded class on the root element.
export default class extends Controller {
  static targets = ["body", "chevron"]
  static values  = { open: { type: Boolean, default: false } }

  connect() {
    this.apply(this.openValue)
  }

  toggle() {
    this.apply(!this.openValue)
    this.openValue = !this.openValue
  }

  apply(open) {
    this.bodyTargets.forEach(b => { b.style.display = open ? '' : 'none' })
    this.element.classList.toggle('qb-expanded', open)
  }
}
