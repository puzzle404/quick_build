import { Controller } from "@hotwired/stimulus"

// Sidebar three-state toggle:
//   default      → no class, the CSS media query decides (desktop = expanded,
//                  tablet < 1024px = collapsed)
//   "0" stored   → forced expanded (.qb-sidebar-expanded), 224px even on tablet
//   "1" stored   → forced collapsed (.qb-sidebar-collapsed), 56px even on desktop
//
// toggle() inspects the CURRENT visual state via offsetWidth and flips. So in
// tablet (where default is collapsed) the first click expands; in desktop
// (where default is expanded) the first click collapses. Either way the
// preference persists in localStorage.
export default class extends Controller {
  static values = { storageKey: { type: String, default: "qb_sidebar_collapsed" } }

  connect() {
    const stored = localStorage.getItem(this.storageKeyValue)
    if (stored === "1") {
      this.element.classList.add("qb-sidebar-collapsed")
    } else if (stored === "0") {
      this.element.classList.add("qb-sidebar-expanded")
    }
  }

  toggle() {
    const isCurrentlyCollapsed = this.element.offsetWidth < 100
    this.element.classList.toggle("qb-sidebar-collapsed", !isCurrentlyCollapsed)
    this.element.classList.toggle("qb-sidebar-expanded",  isCurrentlyCollapsed)
    localStorage.setItem(this.storageKeyValue, isCurrentlyCollapsed ? "0" : "1")
  }
}
