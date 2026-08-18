import { Controller } from "@hotwired/stimulus"

// Bottom sheet del menú "Más" (bottom nav mobile). El controller vive en un
// wrapper que contiene el bottom nav (con el botón que dispara #open) y el
// MobileSheetComponent (con el overlay target).
export default class extends Controller {
  static targets = ["overlay"]

  open() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.dataset.open = "true"
    document.body.style.overflow = "hidden"
  }

  close() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.dataset.open = "false"
    document.body.style.overflow = ""
  }

  // Cierra sólo si el click fue en el backdrop, no en el panel.
  backdropClose(event) {
    if (event.target === this.overlayTarget) this.close()
  }

  closeOnEsc(event) {
    if (event.key === "Escape") this.close()
  }
}
