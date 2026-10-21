import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Estados de carga de toda la app (vive en <body> de los layouts):
//   · Navegación: la barra de progreso de Turbo aparece a los 300 ms, y si la
//     página sigue sin llegar a los 500 ms se suma el overlay con los Bloques
//     (.qb-page-loader) sobre el área de contenido.
//   · Recargas completas (F5, URL tipeada, links sin Turbo): Turbo no se
//     entera, pero la página vieja sigue a la vista hasta que llega la nueva,
//     así que el overlay se arma desde `beforeunload`.
//   · Formularios: el botón que envía muestra el anillo y queda bloqueado
//     mientras dura el envío (también evita el doble click que duplicaba
//     etapas). Turbo ya pone `disabled`; esto le da la señal visual.
// El drawer maneja su propio esqueleto (qb--drawer).
const PROGRESS_BAR_DELAY_MS = 300
const PAGE_LOADER_DELAY_MS = 500
const BUTTON_BUSY_DELAY_MS = 120
const UNLOAD_SAFETY_MS = 10000
const DOWNLOAD_HREF = /\.(csv|pdf|xlsx?|zip|docx?)(\?|#|$)/i

if (Turbo.config?.drive) {
  Turbo.config.drive.progressBarDelay = PROGRESS_BAR_DELAY_MS
} else {
  Turbo.setProgressBarDelay?.(PROGRESS_BAR_DELAY_MS)
}

export default class extends Controller {
  connect() {
    this.onVisit = this.onVisit.bind(this)
    this.onPageDone = this.onPageDone.bind(this)
    this.onSubmitStart = this.onSubmitStart.bind(this)
    this.onSubmitEnd = this.onSubmitEnd.bind(this)

    document.addEventListener("turbo:visit", this.onVisit)
    document.addEventListener("turbo:load", this.onPageDone)
    document.addEventListener("turbo:render", this.onPageDone)
    document.addEventListener("turbo:before-cache", this.onPageDone)
    document.addEventListener("turbo:fetch-request-error", this.onPageDone)
    document.addEventListener("turbo:submit-start", this.onSubmitStart)
    document.addEventListener("turbo:submit-end", this.onSubmitEnd)
    // Volver con el botón del navegador desde bfcache.
    window.addEventListener("pageshow", this.onPageDone)
    this.onBeforeUnload = this.onBeforeUnload.bind(this)
    this.onClick = this.onClick.bind(this)
    window.addEventListener("beforeunload", this.onBeforeUnload)
    document.addEventListener("click", this.onClick, true)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.onVisit)
    document.removeEventListener("turbo:load", this.onPageDone)
    document.removeEventListener("turbo:render", this.onPageDone)
    document.removeEventListener("turbo:before-cache", this.onPageDone)
    document.removeEventListener("turbo:fetch-request-error", this.onPageDone)
    document.removeEventListener("turbo:submit-start", this.onSubmitStart)
    document.removeEventListener("turbo:submit-end", this.onSubmitEnd)
    window.removeEventListener("pageshow", this.onPageDone)
    window.removeEventListener("beforeunload", this.onBeforeUnload)
    document.removeEventListener("click", this.onClick, true)
    this.onPageDone()
  }

  // --- Navegación ---
  onVisit() {
    clearTimeout(this.pageTimer)
    this.pageTimer = setTimeout(() => {
      document.documentElement.classList.add("qb-page-loading")
    }, PAGE_LOADER_DELAY_MS)
  }

  // Una descarga (CSV, PDF…) dispara beforeunload pero la página no cambia:
  // si el overlay se armara ahí quedaría trabado.
  onClick(event) {
    const link = event.target.closest?.("a[href]")
    this.downloadClicked = !!link && (link.hasAttribute("download") || DOWNLOAD_HREF.test(link.getAttribute("href")))
  }

  onBeforeUnload() {
    if (this.downloadClicked) {
      this.downloadClicked = false
      return
    }
    this.onVisit()
    // Red de seguridad: si la navegación se cancela (el navegador la aborta, un
    // diálogo "¿salir?"), no dejar la pantalla cubierta.
    clearTimeout(this.unloadSafety)
    this.unloadSafety = setTimeout(() => this.onPageDone(), UNLOAD_SAFETY_MS)
  }

  onPageDone() {
    clearTimeout(this.pageTimer)
    document.documentElement.classList.remove("qb-page-loading")
    // El snapshot de la caché no debe guardar botones "ocupados".
    document.querySelectorAll(".qb-is-busy").forEach((button) => this.release(button))
  }

  // --- Formularios ---
  onSubmitStart(event) {
    const form = event.target
    const button = event.detail?.formSubmission?.submitter ||
      form.querySelector("button[type=submit], input[type=submit], button:not([type])")
    if (!button) return

    button._qbBusyTimer = setTimeout(() => {
      button.classList.add("qb-is-busy")
      button.setAttribute("aria-busy", "true")
    }, BUTTON_BUSY_DELAY_MS)
    form._qbBusyButton = button
  }

  onSubmitEnd(event) {
    const button = event.target._qbBusyButton
    if (button) this.release(button)
    event.target._qbBusyButton = null
  }

  release(button) {
    clearTimeout(button._qbBusyTimer)
    button.classList.remove("qb-is-busy")
    button.removeAttribute("aria-busy")
  }
}
