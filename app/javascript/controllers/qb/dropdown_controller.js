import { Controller } from "@hotwired/stimulus"

// Generic dropdown menu — toggles a panel relative to its trigger. Closes
// on outside click or ESC. The actual `<select>`/option logic is left to
// the markup (e.g. links that submit a form, or radio inputs that bubble).
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundOutside = this._onOutside.bind(this)
    this.boundKey = this._onKey.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) { this.open() } else { this.close() }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.menuTarget.style.display = "block"
    document.addEventListener("click", this.boundOutside)
    document.addEventListener("keydown", this.boundKey)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.menuTarget.style.display = "none"
    document.removeEventListener("click", this.boundOutside)
    document.removeEventListener("keydown", this.boundKey)
  }

  _onOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
