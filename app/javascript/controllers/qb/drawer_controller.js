import { Controller } from "@hotwired/stimulus"

// Right-anchored slide-over drawer. Two modes:
//   - Frame-driven (the global instance in layouts/constructor.html.erb):
//     declares a `frame` target wrapping the "drawer" turbo-frame; content
//     presence decides open/closed. We watch the frame with a
//     MutationObserver (childList) rather than listening for
//     turbo:frame-load, because turbo:frame-load only fires when the frame
//     completes its OWN navigation lifecycle — it does NOT fire when a
//     turbo_stream response mutates the frame's contents from the outside
//     (e.g. several controllers close the drawer after a create/update via
//     `turbo_stream.update("drawer", "")`, which swaps the frame's children
//     without going through frame navigation). A MutationObserver fires for
//     both cases uniformly, so the panel's open/closed CSS state stays in
//     sync regardless of which mechanism emptied or filled the frame.
//   - Click-driven (local, self-contained instances — e.g. "Invitar
//     miembro", which has no #new route to be frame-scoped against): no
//     `frame` target; a trigger calls #open, the panel calls #close.
export default class extends Controller {
  static targets = ["dialog", "panel", "frame"]

  connect() {
    if (this.hasFrameTarget) {
      this.onFrameMutation = this.onFrameMutation.bind(this)
      this.frameObserver = new MutationObserver(this.onFrameMutation)
      this.frameObserver.observe(this.frameTarget, { childList: true })
      this._setOpen(this._frameHasContent(), { animate: false })
    } else {
      this._setOpen(false, { animate: false })
    }
  }

  disconnect() {
    this.frameObserver?.disconnect()
  }

  onFrameMutation() {
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
