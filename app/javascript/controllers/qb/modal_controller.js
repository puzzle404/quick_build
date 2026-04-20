import { Controller } from "@hotwired/stimulus"

// Centered modal — same API as qb--drawer (open/close/backdrop/keydown)
// but the dialog uses center alignment instead of right-anchored.
export default class extends Controller {
  static targets = ["dialog", "panel"]

  open() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.style.display = "flex"
    document.body.style.overflow = "hidden"
  }

  close() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.style.display = "none"
    document.body.style.overflow = ""
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
