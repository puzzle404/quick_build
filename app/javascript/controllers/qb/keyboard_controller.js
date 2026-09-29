import { Controller } from "@hotwired/stimulus"

// Global ⌘K / ⌘N shortcuts. ⌘K dispatches qb:open on the command palette.
// ⌘N used to Turbo.visit /constructors/projects/new as a full-page
// navigation; now that project creation lives in the unified drawer, it
// clicks the sidebar's own "Nuevo proyecto" trigger instead, so the exact
// same frame-scoped, animated-open path fires regardless of whether the
// user typed ⌘N or clicked the button.
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
      document.querySelector("#qb-sidebar-new-project")?.click()
    }
  }
}
