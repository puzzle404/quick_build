import { Controller } from "@hotwired/stimulus"

// Subtotal en vivo de la fila "agregar ítem" de una lista de materiales:
// cantidad × precio unitario mientras se tipea (antes aparecía recién al
// guardar — feedback 29/09). Mismo formato corto que qb_fmt_cents:
// "$ 2.5M" / "$ 45k" / "$ 800".
export default class extends Controller {
  static targets = ["quantity", "price", "output"]

  connect() {
    this.recalc()
  }

  recalc() {
    const quantity = parseFloat(this.quantityTarget.value)
    const pesos = parseMoney(this.priceTarget.value)
    if (!Number.isFinite(quantity) || !Number.isFinite(pesos)) {
      this.outputTarget.textContent = "—"
      return
    }
    const cents = Math.round(quantity * Math.round(pesos * 100))
    this.outputTarget.textContent = formatCents(cents)
  }
}

// El campo de precio viene con la máscara es-AR de qb--money-input
// ("1.500.000,5"): puntos de miles, coma decimal.
function parseMoney(value) {
  const normalized = (value || "").replace(/\./g, "").replace(",", ".")
  return normalized.trim() === "" ? NaN : parseFloat(normalized)
}

function formatCents(cents) {
  const n = Math.round(cents / 100)
  const abs = Math.abs(n)
  if (abs >= 1_000_000) return `$ ${(n / 1_000_000).toFixed(1)}M`
  if (abs >= 1_000) return `$ ${Math.round(n / 1_000)}k`
  return `$ ${n}`
}
