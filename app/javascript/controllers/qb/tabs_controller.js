import { Controller } from "@hotwired/stimulus"

// Client-side tab switcher for Qb::TabbedPanelComponent.
//
// Markup contract (panels ship WITHOUT display:none so rack_test system specs
// can interact with every panel; this controller hides the non-active ones on
// connect — same degraded-without-JS pattern as qb--drawer):
//   <div data-controller="qb--tabs">
//     <button data-qb--tabs-target="tab" data-action="click->qb--tabs#select" data-index="0" class="qb-tab qb-tab--active">…</button>
//     <button data-qb--tabs-target="tab" data-action="click->qb--tabs#select" data-index="1" class="qb-tab">…</button>
//     <div data-qb--tabs-target="panel" data-index="0" class="qb-tab-panel">…</div>
//     <div data-qb--tabs-target="panel" data-index="1" class="qb-tab-panel">…</div>
//   </div>
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this._activate(this._activeIndex())
  }

  select(event) {
    this._activate(event.currentTarget.dataset.index)
  }

  _activeIndex() {
    const active = this.tabTargets.find(tab => tab.classList.contains("qb-tab--active"))
    return active ? active.dataset.index : (this.tabTargets[0] && this.tabTargets[0].dataset.index) || "0"
  }

  _activate(idx) {
    this.tabTargets.forEach(tab => {
      tab.classList.toggle("qb-tab--active", tab.dataset.index === idx)
    })
    this.panelTargets.forEach(panel => {
      panel.style.display = panel.dataset.index === idx ? "" : "none"
    })
  }
}
