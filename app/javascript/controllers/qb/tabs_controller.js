import { Controller } from "@hotwired/stimulus"

// Client-side tab switcher for Qb::TabbedPanelComponent.
//
// Markup contract:
//   <div data-controller="qb--tabs">
//     <button data-qb--tabs-target="tab" data-action="click->qb--tabs#select" data-index="0" class="tab active">…</button>
//     <button data-qb--tabs-target="tab" data-action="click->qb--tabs#select" data-index="1" class="tab">…</button>
//     <div data-qb--tabs-target="panel" data-index="0" class="tab-panel">…</div>
//     <div data-qb--tabs-target="panel" data-index="1" class="tab-panel" style="display:none;">…</div>
//   </div>
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const idx = event.currentTarget.dataset.index

    this.tabTargets.forEach(tab => {
      tab.classList.toggle("active", tab.dataset.index === idx)
    })

    this.panelTargets.forEach(panel => {
      panel.style.display = panel.dataset.index === idx ? "" : "none"
    })
  }
}
