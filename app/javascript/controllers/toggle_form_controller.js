import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "buttonLabel", "button"]
  static values = { open: Boolean }

  connect() {
    this.update()
  }

  toggle(event) {
    event.preventDefault()
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.update()
  }

  update() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.openValue)
    }

    if (this.hasButtonLabelTarget) {
      this.buttonLabelTarget.textContent = this.openValue ? "Cerrar" : "Agregar material"
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", this.openValue)
    }
  }
}
