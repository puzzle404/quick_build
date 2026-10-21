import { Controller } from "@hotwired/stimulus"

// El prefijo del campo de monto ("$" / "US$") sigue al selector de moneda del
// presupuesto de la obra. Desktop declara el select como target; el form
// mobile (sus filas no aceptan data-*) engancha `change` en el <form> y el
// select se busca por nombre.
const SYMBOLS = { ARS: "$", USD: "US$" }

export default class extends Controller {
  static targets = ["select"]

  sync(event) {
    const select = this.hasSelectTarget ? this.selectTarget : this.element.querySelector("select[name$='[budget_currency]']")
    if (!select || (event && event.target !== select)) return

    const symbol = SYMBOLS[select.value] || "$"
    this.element.querySelectorAll(".qb-money-currency, .m-frow-amount-currency").forEach((el) => { el.textContent = symbol })
  }
}
