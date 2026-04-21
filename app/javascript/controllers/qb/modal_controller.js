import { Controller } from "@hotwired/stimulus"

// Centered modal — same API as qb--drawer (open/close/backdrop/keydown)
// but the dialog uses center alignment instead of right-anchored.
export default class extends Controller {
  static targets = ["dialog", "panel"]

  // Hide the dialog on connect so the markup doesn't need inline
  // display:none (which makes rack_test specs unable to interact with
  // the form). With no JS the dialog stays visible and the form is
  // submittable directly — degraded UX, but functional.
  connect() {
    this._setOpen(false)
  }

  open()  { this._setOpen(true) }
  close() { this._setOpen(false) }

  _setOpen(open) {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.toggle("hidden", !open)
    this.dialogTarget.style.display = open ? "flex" : "none"
    document.body.style.overflow = open ? "hidden" : ""
  }

  backdrop(event) {
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) return
    this.close()
  }

  keydown(event) {
    if (event.key === "Escape" && !this.dialogTarget.classList.contains("hidden")) {
      event.preventDefault()
      this.close()
    }
  }
}
