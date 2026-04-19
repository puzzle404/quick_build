import { Controller } from "@hotwired/stimulus"

// Toggles a "qb-sidebar-collapsed" class and persists the state in localStorage.
// The class itself controls the visual collapse via CSS.
export default class extends Controller {
  static values = { storageKey: { type: String, default: "qb_sidebar_collapsed" } }

  connect() {
    if (localStorage.getItem(this.storageKeyValue) === "1") {
      this.element.classList.add("qb-sidebar-collapsed")
      this.element.dataset.collapsed = "true"
    } else {
      this.element.dataset.collapsed = "false"
    }
  }

  toggle() {
    const isCollapsed = this.element.dataset.collapsed === "true"
    this.element.classList.toggle("qb-sidebar-collapsed", !isCollapsed)
    this.element.dataset.collapsed = isCollapsed ? "false" : "true"
    localStorage.setItem(this.storageKeyValue, isCollapsed ? "0" : "1")
  }
}
