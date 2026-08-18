import { Controller } from "@hotwired/stimulus"

// Mobile segmented control (.m-seg) that toggles named view panels.
// Same idea as qb--view-switcher but stamps data-active on the buttons,
// which is what the .m-seg-btn CSS uses for its pressed style.
// Persists the choice in localStorage.
//
// Markup:
//   <div data-controller="qb--seg-switcher" data-qb--seg-switcher-storage-key-value="qb_x_view">
//     <button class="m-seg-btn" data-qb--seg-switcher-target="btn" data-view="cards"
//             data-action="click->qb--seg-switcher#switch" data-qb--seg-switcher-view-param="cards">…</button>
//     <div data-qb--seg-switcher-target="panel" data-view="cards">…</div>
//   </div>
export default class extends Controller {
  static targets = ["btn", "panel"]
  static values  = { storageKey: { type: String, default: "qb_seg_view" }, default: { type: String, default: "cards" } }

  connect() {
    let view = localStorage.getItem(this.storageKeyValue) || this.defaultValue
    if (!this.panelTargets.some(p => p.dataset.view === view)) view = this.defaultValue
    this.show(view)
  }

  switch(event) {
    const view = event.params.view
    if (!view) return
    this.show(view)
    localStorage.setItem(this.storageKeyValue, view)
  }

  show(view) {
    this.panelTargets.forEach(p => { p.style.display = (p.dataset.view === view ? '' : 'none') })
    this.btnTargets.forEach(b => { b.dataset.active = String(b.dataset.view === view) })
  }
}
