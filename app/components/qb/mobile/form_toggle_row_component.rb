# frozen_string_literal: true

# Switch row inside a FormGroup. CSS provides the iOS-style sliding pill.
class Qb::Mobile::FormToggleRowComponent < ViewComponent::Base
  def initialize(label:, name:, sub: nil, checked: false, value: '1')
    @label = label
    @name = name
    @sub = sub
    @checked = checked
    @value = value
  end
end
