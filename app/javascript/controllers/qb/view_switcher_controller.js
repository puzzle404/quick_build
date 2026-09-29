import { Controller } from "@hotwired/stimulus"

// Toggles between named view panels (e.g. list / grid). Persists choice in
// localStorage so it survives reloads.
//
// Markup:
//   <div data-controller="qb--view-switcher" data-qb--view-switcher-storage-key-value="qb_projects_view">
//     <button data-action="click->qb--view-switcher#switch" data-qb--view-switcher-view-param="list">List</button>
//     <button data-action="click->qb--view-switcher#switch" data-qb--view-switcher-view-param="grid">Grid</button>
//     <div data-qb--view-switcher-target="panel" data-view="list">…</div>
//     <div data-qb--view-switcher-target="panel" data-view="grid">…</div>
//   </div>
export default class extends Controller {
  static targets = ["panel", "btn"]
  static values  = { storageKey: { type: String, default: "qb_view" }, default: { type: String, default: "list" } }

  // La vista guardada puede apuntar a un panel que ya no existe (p. ej. el
  // viejo 'wbs' de qb_planning_view, eliminado del workspace de etapas). Sin
  // este guard quedarían TODOS los paneles en display:none y la pantalla en
  // blanco. Cae al default y se autolimpia en el próximo click. Mismo criterio
  // que qb--seg-switcher (mobile).
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
    this.btnTargets.forEach(b => { b.classList.toggle('qb-active', b.dataset.view === view) })
  }
}
