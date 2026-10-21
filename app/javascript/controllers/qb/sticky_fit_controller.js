import { Controller } from "@hotwired/stimulus"

// Sticky "sólo si entra": el rail del proyecto queda pegado arriba al
// scrollear mientras su alto entra en la pantalla; si es más alto, fluye con
// la página. Nunca tiene scroll propio — un rail sticky más alto que la
// ventana escondía su parte de abajo (había que scrollear "desde afuera").
const TOPBAR_PX = 48
const MARGIN_PX = 8

export default class extends Controller {
  connect() {
    this.update = this.update.bind(this)
    this.resizeObserver = new ResizeObserver(this.update)
    this.resizeObserver.observe(this.element)
    window.addEventListener("resize", this.update)
    this.update()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.removeEventListener("resize", this.update)
  }

  update() {
    const fits = this.element.offsetHeight <= window.innerHeight - TOPBAR_PX - MARGIN_PX
    this.element.classList.toggle("is-sticky", fits)
  }
}
