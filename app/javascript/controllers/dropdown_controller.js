import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    toggle(event) {
        event.stopPropagation()
        this.menuTarget.classList.toggle("hidden")
    }

    close() {
        this.menuTarget.classList.add("hidden")
    }

    closeOnClickOutside(event) {
        if (!this.element.contains(event.target)) {
            this.close()
        }
    }

    connect() {
        this.boundClickOutside = this.closeOnClickOutside.bind(this)
        document.addEventListener("click", this.boundClickOutside)
    }

    disconnect() {
        document.removeEventListener("click", this.boundClickOutside)
    }
}
