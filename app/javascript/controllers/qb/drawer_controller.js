import { Controller } from "@hotwired/stimulus"

// Generic right-anchored slide-over drawer.
//
// Markup contract:
//   <div data-controller="qb--drawer">
//     <button data-action="click->qb--drawer#open">Open</button>
//     <div data-qb--drawer-target="dialog" class="hidden"
//          data-action="click->qb--drawer#backdrop keydown@window->qb--drawer#keydown">
//       <div data-qb--drawer-target="panel">…content…</div>
//       <button data-action="click->qb--drawer#close">×</button>
//     </div>
//   </div>
//
// `dialog` is the full-screen backdrop; `panel` is the inner sheet.
// Click on the backdrop (outside `panel`) closes; ESC also closes.
export default class extends Controller {
  static targets = ["dialog", "panel"]

  // Hide the dialog on connect — markup ships without inline display:none
  // so rack_test specs can interact with the form fields. Without JS the
  // drawer stays visible (degraded UX but functional).
  connect() {
    this._setOpen(false)
  }

  open()  { this._setOpen(true) }
  close() { this._setOpen(false) }

  _setOpen(open) {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.toggle("hidden", !open)
    this.dialogTarget.style.display = open ? "flex" : "none"
    document.body.style.overflow = open ? "hidden" : ""
  }

  backdrop(event) {
    // Only close when the click hits the backdrop itself, not the panel.
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) return
    this.close()
  }

  keydown(event) {
    if (event.key === "Escape" && !this.dialogTarget.classList.contains("hidden")) {
      event.preventDefault()
      this.close()
    }
  }
}
