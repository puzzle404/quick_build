import { Controller } from "@hotwired/stimulus"

// Toast de Qb::ToastComponent: entra deslizándose de izquierda a derecha
// (clase qb-toast-in, animación CSS), se va solo a los `duration` ms y se
// pausa con el mouse encima para que se pueda leer con calma. La barrita
// inferior muestra cuánto le queda.
export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.remaining = this.durationValue
    requestAnimationFrame(() => this.element.classList.add("qb-toast-in"))
    this.resume()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  pause() {
    clearTimeout(this.timer)
    this.remaining -= Date.now() - this.startedAt
    this.element.classList.add("qb-toast-paused")
  }

  resume() {
    this.element.classList.remove("qb-toast-paused")
    this.startedAt = Date.now()
    this.timer = setTimeout(() => this.dismiss(), Math.max(this.remaining, 0))
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.classList.remove("qb-toast-in")
    this.element.classList.add("qb-toast-out")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
    // Red de seguridad si la animación no corre (prefers-reduced-motion).
    setTimeout(() => this.element.remove(), 400)
  }
}
