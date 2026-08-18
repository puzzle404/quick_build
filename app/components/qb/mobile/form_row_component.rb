# frozen_string_literal: true

# Single text/textarea/select input inside a FormGroup. The label is the small
# mono uppercase eyebrow; the input chip sits below on bg-sunken.
#
# `inputmode`/`min`/`max`/`step` son opcionales y sólo aplican al input de
# texto: sin ellos un campo numérico (avance %) abre el teclado alfabético en
# el teléfono, que es justo lo que no se quiere en obra.
class Qb::Mobile::FormRowComponent < ViewComponent::Base
  def initialize(label:, name: nil, value: nil, placeholder: nil, type: "text",
                 textarea: false, select: false, options: nil, helper: nil,
                 required: false, autocomplete: nil, inputmode: nil,
                 min: nil, max: nil, step: nil)
    @label = label
    @name = name
    @value = value
    @placeholder = placeholder
    @type = type
    @textarea = textarea
    @select = select
    @options = options
    @helper = helper
    @required = required
    @autocomplete = autocomplete
    @inputmode = inputmode
    @min = min
    @max = max
    @step = step
  end

  private

  # tag.attributes escapa y omite los nil solo; antes el autocomplete se
  # interpolaba con html_safe a mano.
  def input_attributes
    { autocomplete: @autocomplete, inputmode: @inputmode,
      min: @min, max: @max, step: @step }.compact
  end
end
