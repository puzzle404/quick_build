import { Controller } from "@hotwired/stimulus"

// Lightweight command palette: open via custom event "qb:open" (or click on
// the trigger), filter items client-side as user types, navigate with arrows,
// activate with Enter.
export default class extends Controller {
  static targets = ["dialog", "input", "item"]

  connect() {
    this.activeIndex = 0
    this.element.addEventListener("qb:open", () => this.open())
  }

  open() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.style.display = "flex"
    requestAnimationFrame(() => this.inputTarget?.focus())
    this.activeIndex = 0
    this.refresh()
  }

  close() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.style.display = "none"
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.refresh()
  }

  filter() {
    this.activeIndex = 0
    this.refresh()
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = Math.min(this.activeIndex + 1, this.visibleCount - 1)
      this.refresh()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = Math.max(this.activeIndex - 1, 0)
      this.refresh()
    } else if (event.key === "Enter") {
      event.preventDefault()
      const active = this.itemTargets.find(el => el.classList.contains("qb-active"))
      active?.click()
    }
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  refresh() {
    if (!this.hasInputTarget) return
    const q = this.inputTarget.value.trim().toLowerCase()
    let visible = 0
    this.itemTargets.forEach((el) => {
      const label = (el.dataset.qbLabel || el.textContent || "").toLowerCase()
      const matches = !q || label.includes(q)
      el.style.display = matches ? "" : "none"
      if (matches) {
        el.classList.toggle("qb-active", visible === this.activeIndex)
        visible++
      } else {
        el.classList.remove("qb-active")
      }
    })
    this.visibleCount = visible
  }
}
