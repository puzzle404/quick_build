import { Controller } from "@hotwired/stimulus"

// Global ⌘K / ⌘N shortcuts. Looks up the command-palette element by its
// controller attribute (no Stimulus targets needed) and dispatches qb:open
// on it. ⌘N falls back to navigating to /constructors/projects/new.
export default class extends Controller {
  connect() {
    this.handler = this.onKey.bind(this)
    window.addEventListener("keydown", this.handler)
  }

  disconnect() {
    window.removeEventListener("keydown", this.handler)
  }

  onKey(event) {
    const mod = event.metaKey || event.ctrlKey
    if (!mod) return

    const key = event.key.toLowerCase()
    if (key === "k") {
      event.preventDefault()
      const palette = document.querySelector("[data-controller~='qb--cmd-palette']")
      if (palette) palette.dispatchEvent(new CustomEvent("qb:open"))
    } else if (key === "n") {
      const active = document.activeElement
      const tag = (active?.tagName || "").toLowerCase()
      if (tag === "input" || tag === "textarea" || (active?.isContentEditable)) return
      event.preventDefault()
      const url = "/constructors/projects/new"
      if (window.Turbo) {
        window.Turbo.visit(url)
      } else {
        window.location.href = url
      }
    }
  }
}
