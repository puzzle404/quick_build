import { Controller } from "@hotwired/stimulus"

// Centered modal — same API as qb--drawer (open/close/backdrop/keydown)
// but the dialog uses center alignment instead of right-anchored.
export default class extends Controller {
  static targets = ["dialog", "panel"]
  // openOnConnect: true for modals lazily loaded into a Turbo Frame (e.g. the
  // project_modal frame). They must appear as soon as the frame swaps them in.
  // Inline modals leave it false so they start hidden until their trigger.
  static values = { openOnConnect: Boolean }

  // Inline modals hide on connect (markup ships visible so rack_test can reach
  // the form; with no JS the dialog stays visible — degraded but functional).
  // Modals lazily loaded into the project_modal Turbo Frame open immediately
  // (an inline modal is never inside that frame, so this stays robust without
  // depending on a per-instance attribute being parsed at connect time).
  connect() {
    const inProjectModalFrame = this.element.closest("turbo-frame#project_modal") != null
    this._setOpen(this.openOnConnectValue === true || inProjectModalFrame)
  }

  open()  { this._setOpen(true) }
  close() { this._setOpen(false) }

  // Para forms que viven dentro de la modal: cierran la modal sólo si la
  // respuesta fue exitosa (turbo:submit-end emite event.detail.success).
  // Si hay validation error, la modal queda abierta para que el usuario corrija.
  closeOnSuccess(event) {
    if (event?.detail?.success) {
      this._setOpen(false)
      // Reset de todos los forms dentro del panel para que la próxima apertura
      // empiece vacía (caso típico: "Nueva nota" se reusa varias veces).
      if (this.hasPanelTarget) {
        this.panelTarget.querySelectorAll("form").forEach((f) => f.reset())
      }
    }
  }

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
