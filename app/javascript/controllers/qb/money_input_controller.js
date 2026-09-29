import { Controller } from "@hotwired/stimulus"

// Máscara de montos es-AR mientras se tipea: "1500000,5" → "1.500.000,5".
// El "." de miles lo pone el controller (los puntos que tipea el usuario se
// ignoran); la "," es el decimal, con 2 dígitos como máximo. La tecla "." del
// teclado numérico se toma como coma, que es lo que espera cualquiera que
// cargue plata en Argentina. El server sigue parseando con Money::ArsParser,
// que entiende exactamente este formato.
export default class extends Controller {
  connect() {
    this.element.value = this._format(this.element.value)
  }

  // Punto del teclado principal: se ignora (los miles los agrupa el
  // controller; si lo tomáramos como decimal, tipear "1.500" daría "1,50").
  // Punto del numérico: coma decimal.
  keydown(event) {
    if (event.key !== "." && event.code !== "NumpadDecimal") return
    event.preventDefault()
    if (event.code === "NumpadDecimal") {
      if (this.element.value.includes(",")) return
      const { selectionStart: start, selectionEnd: end, value } = this.element
      this.element.value = value.slice(0, start) + "," + value.slice(end)
      this.element.setSelectionRange(start + 1, start + 1)
      this.format()
    }
  }

  format() {
    const input = this.element
    const caret = input.selectionStart ?? input.value.length
    // Cuántos dígitos (y coma) hay antes del cursor: es lo único estable
    // entre el valor viejo y el reformateado.
    const significantBefore = input.value.slice(0, caret).replace(/[^\d,]/g, "").length

    const formatted = this._format(input.value)
    input.value = formatted

    let pos = 0
    let seen = 0
    while (pos < formatted.length && seen < significantBefore) {
      if (/[\d,]/.test(formatted[pos])) seen++
      pos++
    }
    if (document.activeElement === input) input.setSelectionRange(pos, pos)
  }

  _format(raw) {
    if (raw == null) return ""
    let value = String(raw).trim()
    if (value === "") return ""

    // Valor que ya viene de la base con punto decimal ("1500.5", "1500.50")
    // y sin coma: lo pasamos a coma antes de tirar los puntos.
    if (!value.includes(",") && /^\d+\.\d{1,2}$/.test(value)) value = value.replace(".", ",")

    const negative = value.startsWith("-")
    const [intRaw, ...rest] = value.replace(/[^\d,]/g, "").split(",")
    const hasComma = rest.length > 0
    const decimals = rest.join("").slice(0, 2)

    const intDigits = intRaw.replace(/^0+(?=\d)/, "")
    const grouped = intDigits.replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    const intPart = grouped === "" && hasComma ? "0" : grouped

    return (negative ? "-" : "") + intPart + (hasComma ? "," + decimals : "")
  }
}
