import { Controller } from "@hotwired/stimulus"

// Tiny bridge controller: a button can declare data-controller="qb--cmd-palette-trigger"
// and clicking it dispatches the qb:open event on whichever element carries the
// real palette controller.
export default class extends Controller {
  open() {
    const palette = document.querySelector("[data-controller~='qb--cmd-palette']")
    if (palette) palette.dispatchEvent(new CustomEvent("qb:open"))
  }
}
