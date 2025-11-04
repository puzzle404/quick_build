import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.timeoutId = null
    console.log(`SearchSubmitController connected with delay: `)
  }

  submit() {
    clearTimeout(this.timeoutId)
    this.timeoutId = setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }
}
