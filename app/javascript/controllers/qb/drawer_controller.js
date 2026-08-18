import { Controller } from "@hotwired/stimulus"

// Right-anchored slide-over drawer. Two modes:
//   - Frame-driven (the global instance in layouts/constructor.html.erb):
//     declares a `frame` target wrapping the "drawer" turbo-frame; content
//     presence after any turbo:frame-load decides open/closed, so no view
//     needs its own open-on-connect flag or closest("turbo-frame#...") check.
//   - Click-driven (local, self-contained instances — e.g. "Invitar
//     miembro", which has no #new route to be frame-scoped against): no
//     `frame` target; a trigger calls #open, the panel calls #close.
export default class extends Controller {
  static targets = ["dialog", "panel", "frame"]

  connect() {
    if (this.hasFrameTarget) {
      this.onFrameLoad = this.onFrameLoad.bind(this)
      this.frameTarget.addEventListener("turbo:frame-load", this.onFrameLoad)
      this._setOpen(this._frameHasContent(), { animate: false })
    } else {
      this._setOpen(false, { animate: false })
    }
  }

  disconnect() {
    if (this.hasFrameTarget) this.frameTarget.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  onFrameLoad() {
    this._setOpen(this._frameHasContent())
  }

  open() { this._setOpen(true) }

  // Cierre disparado por el botón × / backdrop / Escape: vacía el frame para
  // que la próxima apertura pida contenido fresco en vez de reusar el último
  // estado (ej: "Cancelar" no debe dejar la próxima apertura mostrando el
  // formulario a medio llenar de la vez anterior).
  close() {
    this._setOpen(false)
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
      this.frameTarget.removeAttribute("src")
    }
  }

  backdrop(event) {
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) return
    this.close()
  }

  keydown(event) {
    if (event.key === "Escape" && this.dialogTarget.classList.contains("qb-drawer-open")) {
      event.preventDefault()
      this.close()
    }
  }

  _frameHasContent() {
    return this.hasFrameTarget && this.frameTarget.innerHTML.trim().length > 0
  }

  _setOpen(open, { animate = true } = {}) {
    if (!this.hasDialogTarget) return
    if (!animate) this.dialogTarget.classList.add("qb-drawer-no-transition")
    this.dialogTarget.classList.toggle("qb-drawer-open", open)
    this.dialogTarget.toggleAttribute("aria-hidden", !open)
    document.body.style.overflow = open ? "hidden" : ""
    if (open && this.hasPanelTarget) {
      requestAnimationFrame(() => this.panelTarget.focus())
    }
    if (!animate) {
      requestAnimationFrame(() => this.dialogTarget.classList.remove("qb-drawer-no-transition"))
    }
  }
}
