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
const SKELETON_DELAY_MS = 200
// Persistencia (frame-driven): la vista abierta queda en `?drawer=<path>` para
// que un F5 la vuelva a abrir, y un turbo_stream.refresh ajeno al drawer lo
// conserva tal cual (con lo tipeado): el shell es data-turbo-permanent en el
// layout y en cada render de Turbo Drive se decide si sigue o se cierra —
// sigue sólo en ese refresh; se cierra al navegar a otra página y cuando el
// refresh viene de un envío del propio drawer (la tarea terminó, ej: "Guardar
// etapa").
const URL_PARAM = "drawer"
const OWN_SUBMIT_WINDOW_MS = 5000

export default class extends Controller {
  static targets = ["dialog", "panel", "frame", "backButton", "skeleton"]
  // true en la instancia global del <body> (frame-driven). Explícito y no
  // "tiene frame target": durante un render con el shell permanente Turbo
  // conecta el body nuevo con un placeholder en lugar del shell, y en ese
  // instante no hay frame — se la confundía con un drawer click-driven.
  static values = { global: Boolean }

  // Handlers enlazados una sola vez por instancia: se enganchan y
  // desenganchan varias veces (cada frame que conecta) y tienen que ser la
  // misma referencia para que removeEventListener funcione.
  initialize() {
    this.onFrameMutation = this.onFrameMutation.bind(this)
    this.onFrameFetch = this.onFrameFetch.bind(this)
    this.onFrameResponse = this.onFrameResponse.bind(this)
    this.onSubmitStart = this.onSubmitStart.bind(this)
    this.onBeforeStreamRender = this.onBeforeStreamRender.bind(this)
    this.onBeforeRender = this.onBeforeRender.bind(this)
    this.onSubmitEnd = this.onSubmitEnd.bind(this)
  }

  connect() {
    // Pila de URLs de las que se puede "volver": un sub-nivel por cada vez
    // que se navega a una vista nueva desde una ya abierta (ej: detalle de
    // etapa → "Nueva nota"). Vacía = estamos en el primer nivel, así que
    // volver equivale a cerrar del todo.
    this._history = []
    if (this.globalValue) {
      document.addEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
      document.addEventListener("turbo:before-render", this.onBeforeRender)
      this._setOpen(this._frameHasContent(), { animate: false })
      // Diferido: si este render conserva el shell permanente, Turbo recién
      // mete el frame viejo (con contenido) después de conectar este
      // controller; restaurar desde la URL antes lo pisaría.
      requestAnimationFrame(() => {
        if (this.hasFrameTarget && !this._frameHasContent()) this._restoreFromUrl()
      })
    } else {
      this._setOpen(false, { animate: false })
      // Click-driven: nadie vacía un frame al guardar, así que sin esto el
      // panel quedaba abierto tras un alta exitosa y el usuario, creyendo que
      // no se había guardado, reenviaba el form (etapas duplicadas). Los
      // errores de validación (success = false) lo dejan abierto.
      this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
    }
    this._syncBackButton()
  }

  disconnect() {
    this._detachFrame()
    clearTimeout(this.skeletonTimer)
    document.removeEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
    document.removeEventListener("turbo:before-render", this.onBeforeRender)
    this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  // El frame se sigue por callbacks de target y no una sola vez en connect:
  // con el shell permanente, Turbo cambia el frame por el de la página
  // anterior DESPUÉS de conectar el controller, y un observer/listener
  // enganchado al primero quedaba escuchando un nodo descartado.
  frameTargetConnected(frame) {
    this._attachFrame(frame)
    this._setOpen(this._frameHasContent(), { animate: false })
    this._syncBackButton()
  }

  frameTargetDisconnected(frame) {
    if (frame === this.frameElement) this._detachFrame()
  }

  _attachFrame(frame) {
    this._detachFrame()
    this.frameElement = frame
    this._frameUrl = frame.getAttribute("src")
    this.frameObserver = new MutationObserver(this.onFrameMutation)
    this.frameObserver.observe(frame, { childList: true })
    frame.addEventListener("turbo:before-fetch-request", this.onFrameFetch)
    frame.addEventListener("turbo:before-fetch-response", this.onFrameResponse)
    frame.addEventListener("turbo:submit-start", this.onSubmitStart)
  }

  _detachFrame() {
    this.frameObserver?.disconnect()
    this.frameObserver = null
    const frame = this.frameElement
    if (!frame) return
    frame.removeEventListener("turbo:before-fetch-request", this.onFrameFetch)
    frame.removeEventListener("turbo:before-fetch-response", this.onFrameResponse)
    frame.removeEventListener("turbo:submit-start", this.onSubmitStart)
    this.frameElement = null
  }

  onSubmitEnd(event) {
    if (!event.detail?.success) return
    if (this.hasDialogTarget && !this.dialogTarget.contains(event.target)) return
    event.target.reset?.()
    this.close()
  }

  // GET lento del frame (abrir una vista, navegar dentro del drawer): pasados
  // SKELETON_DELAY_MS sin respuesta se muestra el esqueleto con los Bloques en
  // vez de un panel vacío o la vista anterior congelada. Los envíos de forms
  // (POST/PATCH) no: ahí el feedback es el botón ocupado (qb--loading).
  onFrameFetch(event) {
    if (!this._isOwnFetch(event)) return
    this._lastFetchMethod = (event.detail?.fetchOptions?.method || "GET").toUpperCase()
    if (!this.hasSkeletonTarget) return
    const method = (event.detail?.fetchOptions?.method || "GET").toUpperCase()
    if (method !== "GET") return

    clearTimeout(this.skeletonTimer)
    this.skeletonTimer = setTimeout(() => {
      if (!this.frameTarget.hasAttribute("busy") && this.frameTarget.getAttribute("aria-busy") !== "true") return
      this.frameTarget.replaceChildren(this.skeletonTarget.content.cloneNode(true))
    }, SKELETON_DELAY_MS)
  }

  onFrameMutation() {
    this._setOpen(this._frameHasContent())
    this._syncBackButton()
    this._syncUrl()
  }

  // --- Persistencia ---

  // Qué URL representa lo que muestra el drawer: la del último GET (o el GET
  // final tras un redirect de un POST). Una respuesta 422 de un POST no: esa
  // URL (ej: /expenses) no es una vista de drawer.
  onFrameResponse(event) {
    if (!this._isOwnFetch(event)) return
    const response = event.detail?.fetchResponse
    if (!response?.succeeded) return
    if (this._lastFetchMethod === "GET" || response.redirected) {
      this._frameUrl = response.location?.href || this._frameUrl
    }
  }

  onSubmitStart(event) {
    if (event.target.closest("turbo-frame") === this.frameElement) this._ownSubmitAt = Date.now()
  }

  onBeforeStreamRender(event) {
    if (event.target.getAttribute("action") !== "refresh") return
    if (!this._isOpen()) return

    if (this._ownSubmitAt && Date.now() - this._ownSubmitAt < OWN_SUBMIT_WINDOW_MS) {
      // El refresh lo causó un guardado del propio drawer: se cierra (y sin
      // el param, así el GET del refresh no lo vuelve a abrir).
      this._ownSubmitAt = null
      this._keepUntil = 0
      this._frameUrl = null
      this._writeUrlParam(null)
    } else {
      // Refresh ajeno: el drawer sobrevive al próximo render de la página.
      this._keepUntil = Date.now() + OWN_SUBMIT_WINDOW_MS
    }
  }

  // El shell es permanente, así que Turbo lo conserva en TODO render: acá se
  // cierra salvo en el refresh que pidió conservarlo.
  onBeforeRender() {
    const keep = this._keepUntil && Date.now() < this._keepUntil
    this._keepUntil = 0
    if (!keep && this._isOpen()) this.close()
  }

  _syncUrl() {
    if (this._isOpen() && this._frameHasContent()) {
      const path = this._sameOriginPath(this._frameUrl || this.frameTarget.getAttribute("src"))
      if (path) this._writeUrlParam(path)
    } else if (!this._isOpen()) {
      this._frameUrl = null
      this._writeUrlParam(null)
    }
  }

  _restoreFromUrl() {
    const path = this._sameOriginPath(new URL(window.location.href).searchParams.get(URL_PARAM))
    if (!path) return
    this._setOpen(true, { animate: false })
    this.frameTarget.src = path
  }

  _writeUrlParam(path) {
    const url = new URL(window.location.href)
    if ((url.searchParams.get(URL_PARAM) || null) === path) return
    if (path) url.searchParams.set(URL_PARAM, path)
    else url.searchParams.delete(URL_PARAM)
    // replaceState conservando el state de Turbo (su restorationIdentifier):
    // abrir/cerrar el drawer no suma entradas al historial del navegador.
    window.history.replaceState(window.history.state, "", url)
  }

  // Sólo paths propios ("/constructors/…"): nunca otro origen ni "//host".
  _sameOriginPath(value) {
    if (!value) return null
    try {
      const url = new URL(value, window.location.origin)
      if (url.origin !== window.location.origin) return null
      url.searchParams.delete(URL_PARAM)
      return url.pathname + url.search
    } catch (_error) {
      return null
    }
  }

  // Requests del frame del drawer o de forms directamente dentro de él; no
  // los de frames anidados (tabs, listas lazy) que también burbujean hasta acá.
  _isOwnFetch(event) {
    const target = event.target
    return target === this.frameElement || target.closest?.("turbo-frame") === this.frameElement
  }

  _isOpen() {
    return this.hasDialogTarget && this.dialogTarget.classList.contains("qb-drawer-open")
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
