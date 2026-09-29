import { Controller } from "@hotwired/stimulus"

// Compartir un texto (ubicación de la obra, etc.). En el celular abre la hoja
// nativa de compartir (WhatsApp, mail…); en la compu, o si el navegador no la
// tiene, lo copia al portapapeles y avisa con un toast.
export default class extends Controller {
  static values = { title: String, text: String }

  async share(event) {
    event?.preventDefault()

    if (navigator.share && matchMedia("(pointer: coarse)").matches) {
      try {
        await navigator.share({ title: this.titleValue, text: this.textValue })
        return
      } catch (error) {
        if (error?.name === "AbortError") return // el usuario cerró la hoja
      }
    }

    try {
      await navigator.clipboard.writeText(this.textValue)
      this.toast("Ubicación copiada: pegala donde la necesites.", "ok")
    } catch (_error) {
      this.toast("No pudimos copiar la ubicación. Usá el botón de WhatsApp o Google Maps.", "bad")
    }
  }

  // Mismo markup que Qb::ToastComponent, para que lo anime qb--toast.
  toast(message, tone) {
    const stack = document.getElementById("qb_toasts")
    if (!stack) return

    const el = document.createElement("div")
    el.className = `qb-toast qb-toast--${tone}`
    el.setAttribute("role", tone === "bad" ? "alert" : "status")
    el.dataset.controller = "qb--toast"
    el.dataset.action = "mouseenter->qb--toast#pause mouseleave->qb--toast#resume"
    el.style.setProperty("--qb-toast-duration", "5000ms")

    const msg = document.createElement("div")
    msg.className = "qb-toast-msg"
    msg.textContent = message
    const close = document.createElement("button")
    close.type = "button"
    close.className = "qb-toast-close"
    close.setAttribute("aria-label", "Cerrar aviso")
    close.dataset.action = "click->qb--toast#dismiss"
    close.textContent = "×"
    const timer = document.createElement("span")
    timer.className = "qb-toast-timer"

    el.append(msg, close, timer)
    stack.append(el)
  }
}
