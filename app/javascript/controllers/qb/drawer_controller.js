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
  static targets = ["dialog", "panel", "frame", "backButton"]

  connect() {
    // Pila de URLs de las que se puede "volver": un sub-nivel por cada vez
    // que se navega a una vista nueva desde una ya abierta (ej: detalle de
    // etapa → "Nueva nota"). Vacía = estamos en el primer nivel, así que
    // volver equivale a cerrar del todo.
    this._history = []
    if (this.hasFrameTarget) {
      this.onFrameMutation = this.onFrameMutation.bind(this)
      this.frameObserver = new MutationObserver(this.onFrameMutation)
      this.frameObserver.observe(this.frameTarget, { childList: true })
      this._setOpen(this._frameHasContent(), { animate: false })
    } else {
      this._setOpen(false, { animate: false })
    }
    this._syncBackButton()
  }

  disconnect() {
    this.frameObserver?.disconnect()
  }

  onFrameMutation() {
    this._setOpen(this._frameHasContent())
    this._syncBackButton()
  }

  // Se dispara con cada trigger "data-action=click->qb--drawer#open": en ese
  // momento el frame todavía tiene el src/contenido ANTERIOR (el click nativo
  // que dispara la navegación de Turbo llega después, en el mismo evento), así
  // que es el lugar correcto para apilarlo como "adonde volver" antes de que
  // lo reemplace la vista nueva. Src vacío (primer nivel, drawer recién
  // abierto) no se apila: no hay nada previo a lo que volver.
  open() {
    if (this.hasFrameTarget) {
      const current = this.frameTarget.getAttribute("src")
      if (current) this._history.push(current)
    }
    this._setOpen(true)
    this._syncBackButton()
  }

  // "Volver": deshace la navegación a la vista actual y muestra la anterior,
  // sin cerrar el panel. Es la acción de los botones "Cancelar" y de la
  // flecha ‹ del header — cancelar una acción vuelve a lo que se estaba
  // viendo, no cierra todo el drawer. Sin nada en la pila (primer nivel) se
  // comporta igual que close().
  back() {
    const previous = this._history.pop()
    if (previous && this.hasFrameTarget) {
      this.frameTarget.src = previous
      this._syncBackButton()
    } else {
      this.close()
    }
  }

  // Cierre disparado por el botón × / backdrop / Escape: vacía el frame para
  // que la próxima apertura pida contenido fresco en vez de reusar el último
  // estado (ej: "Cancelar" no debe dejar la próxima apertura mostrando el
  // formulario a medio llenar de la vez anterior). Cierra el drawer entero
  // sin importar cuántos niveles se hayan apilado.
  close() {
    this._setOpen(false)
    this._history = []
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

  // El botón ‹ vive en el header de cada vista, así que se re-renderiza con
  // cada navegación — hay que volver a sincronizar su visibilidad cada vez
  // (Stimulus resuelve backButtonTarget contra el DOM actual, así que esto
  // siempre apunta al botón recién insertado).
  _syncBackButton() {
    if (!this.hasBackButtonTarget) return
    this.backButtonTarget.style.display = this._history.length > 0 ? "" : "none"
  }

  _setOpen(open, { animate = true } = {}) {
    if (!this.hasDialogTarget) return
    if (!animate) this.dialogTarget.classList.add("qb-drawer-no-transition")
    this.dialogTarget.classList.toggle("qb-drawer-open", open)
    // Valor explícito: `toggleAttribute` dejaba `aria-hidden=""` al cerrar, y
    // ARIA lee la cadena vacía como "false" — justo lo contrario del intento.
    this.dialogTarget.setAttribute("aria-hidden", open ? "false" : "true")
    document.body.style.overflow = open ? "hidden" : ""
    if (open && this.hasPanelTarget) {
      requestAnimationFrame(() => this.panelTarget.focus())
    }
    if (!animate) {
      requestAnimationFrame(() => this.dialogTarget.classList.remove("qb-drawer-no-transition"))
    }
  }
}
