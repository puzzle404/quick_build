import { Controller } from "@hotwired/stimulus"

// Simple modal controller to clear the turbo frame and restore scroll
export default class extends Controller {
  connect() {
    this.frameElement = this.element.closest("turbo-frame")
    this.previousOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    this.restoreScroll()
  }

  close(event) {
    event?.preventDefault()
    if (this.frameElement) {
      this.frameElement.innerHTML = ""
    } else {
      this.element.remove()
    }
    this.restoreScroll()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
  }

  restoreScroll() {
    document.body.style.overflow = this.previousOverflow || ""
  }
}
