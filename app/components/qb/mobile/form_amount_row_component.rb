# frozen_string_literal: true

# Currency amount input — large mono digits inside a bg-sunken chip. Used in
# the expense/payment modals.
#
# El importe SIEMPRE se tipea en pesos (el controller lo convierte a centavos
# con Money::ArsParser). Pasando `cents:` el componente hace la conversión de
# ida para mostrar: sin separador de miles y con coma decimal sólo cuando hace
# falta ("4500", no "4500.0"), así reeditar y guardar devuelve exactamente el
# mismo número.
class Qb::Mobile::FormAmountRowComponent < ViewComponent::Base
  def initialize(label:, name:, value: nil, cents: nil, currency: "$", sub: nil, placeholder: "0")
    @label = label
    @name = name
    @value = value
    @cents = cents
    @currency = currency
    @sub = sub
    @placeholder = placeholder
  end

  private

  def display_value
    @value.presence || pesos_from_cents
  end

  def pesos_from_cents
    return nil if @cents.blank?

    cents = @cents.to_i
    return (cents / 100).to_s if (cents % 100).zero?

    # Kernel.format explícito: ViewComponent::Base define su propio #format
    # (el de render, sin argumentos) y el `format("%.2f", n)` pelado explota
    # con ArgumentError apenas el importe tiene centavos.
    Kernel.format("%.2f", cents / 100.0).tr(".", ",")
  end
end
