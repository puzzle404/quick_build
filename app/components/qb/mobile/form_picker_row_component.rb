# frozen_string_literal: true

# Picker-style row: label left, value right with chevron. Used for things like
# project selectors, date pickers, or fields that present a follow-up sheet.
class Qb::Mobile::FormPickerRowComponent < ViewComponent::Base
  def initialize(label:, value: nil, placeholder: 'Elegir…', href: nil, required: false)
    @label = label
    @value = value
    @placeholder = placeholder
    @href = href
    @required = required
  end
end
