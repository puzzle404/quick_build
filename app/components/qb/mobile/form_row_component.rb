# frozen_string_literal: true

# Single text/textarea/select input inside a FormGroup. The label is the small
# mono uppercase eyebrow; the input chip sits below on bg-sunken.
class Qb::Mobile::FormRowComponent < ViewComponent::Base
  def initialize(label:, name: nil, value: nil, placeholder: nil, type: 'text',
                 textarea: false, select: false, options: nil, helper: nil,
                 required: false, autocomplete: nil)
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
  end
end
