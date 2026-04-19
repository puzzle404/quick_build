import { Controller } from "@hotwired/stimulus"

// Theme/density/layout switcher. Persists choices in localStorage and applies
// them as data-* attributes on <html> so CSS @theme overrides take effect.
export default class extends Controller {
  static values = {
    initial: { type: Object, default: { theme: "graphite", density: "cozy", layout: "sidebar" } },
    storageKey: { type: String, default: "qb_tweaks" },
  }
  static targets = ["panel"]

  connect() {
    const stored = this._readStored()
    this._apply({ ...this.initialValue, ...stored })
    this.element.addEventListener("qb:open-tweaks", () => this.open())
  }

  open() {
    this.panelTarget?.classList.remove("hidden")
    if (this.hasPanelTarget) this.panelTarget.style.display = "block"
  }

  close() {
    this.panelTarget?.classList.add("hidden")
    if (this.hasPanelTarget) this.panelTarget.style.display = "none"
  }

  set(event) {
    const key = event.params.key
    const value = event.params.value
    if (!key || !value) return
    const current = { ...this.initialValue, ...this._readStored(), [key]: value }
    localStorage.setItem(this.storageKeyValue, JSON.stringify(current))
    this._apply(current)
    this._refreshActive(current)
  }

  _readStored() {
    try { return JSON.parse(localStorage.getItem(this.storageKeyValue) || "{}") } catch { return {} }
  }

  _apply(t) {
    const root = document.documentElement
    if (t.theme)   root.dataset.theme = t.theme
    if (t.density) root.dataset.density = t.density
    if (t.layout)  root.dataset.layout = t.layout
  }

  _refreshActive(t) {
    this.element.querySelectorAll("[data-qb-tweak-key]").forEach((btn) => {
      const k = btn.dataset.qbTweakKey
      const v = btn.dataset.qbTweakValue
      btn.classList.toggle("qb-active", t[k] === v)
    })
  }
}
