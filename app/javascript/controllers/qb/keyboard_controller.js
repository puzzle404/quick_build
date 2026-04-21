import { Controller } from "@hotwired/stimulus"

// Global ⌘K / ⌘N shortcuts. Looks up the command-palette element by its
// controller attribute (no Stimulus targets needed) and dispatches qb:open
// on it.
//
// ⌘N navigates (Turbo.visit) to /constructors/projects/new instead of
// opening the wizard as an inline modal on top of whatever page the user
// is on. This is intentional: the wizard has its own page (nicer layout,
// deep-linkable URL, back-button friendly) and reproducing it as a
// layer-wide modal requires carrying form state across frames with no
// obvious UX win. The handoff's NewProject screen also renders as a
// dedicated view, not a modal over the dashboard.
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
