# frozen_string_literal: true

# Input de montos en pesos: prefijo "$" + máscara es-AR mientras se tipea
# (separador de miles "." y hasta 2 decimales con ",", controller Stimulus
# qb--money-input). Es texto libre, no number_field: el server lo pasa a
# centavos con Money::ArsParser, así que el atributo tiene que ser el
# virtual en pesos (`amount_pesos`, `budget_pesos`, …), nunca `*_cents`.
#
#   render Qb::MoneyFieldComponent.new(form: f, method: :amount_pesos, value: "1500,50", required: true)
#
# `compact: true` lo deja sin borde ni fondo, para filas de tabla inline.
class Qb::MoneyFieldComponent < ViewComponent::Base
  def initialize(form:, method:, value: nil, currency: "$", compact: false, **html_options)
    @form = form
    @method = method
    @value = value
    @currency = currency
    @compact = compact
    @html_options = html_options
  end

  attr_reader :form, :method, :currency

  def wrapper_class
    @compact ? "qb-money qb-money--compact" : "qb-money"
  end

  def input_options
    data = (@html_options[:data] || {}).merge(
      controller: [ "qb--money-input", @html_options.dig(:data, :controller) ].compact.join(" "),
      action: [ "input->qb--money-input#format keydown->qb--money-input#keydown", @html_options.dig(:data, :action) ].compact.join(" ")
    )
    opts = @html_options.except(:data).merge(
      class: [ @compact ? nil : "qb-input", "qb-money-input", @html_options[:class] ].compact.join(" "),
      inputmode: "decimal",
      autocomplete: "off",
      placeholder: @html_options.fetch(:placeholder, "0,00"),
      data: data,
      # Siempre explícito (aunque sea nil): los atributos `*_pesos` son
      # virtuales y la mayoría de los modelos no tiene getter, así que
      # text_field sin `value:` explotaba con NoMethodError.
      value: @value
    )
  end
end
