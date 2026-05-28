# frozen_string_literal: true

# Currency amount input — large mono digits inside a bg-sunken chip. Used in
# the expense/payment modals.
class Qb::Mobile::FormAmountRowComponent < ViewComponent::Base
  def initialize(label:, name:, value: nil, currency: '$', sub: nil, placeholder: '0')
    @label = label
    @name = name
    @value = value
    @currency = currency
    @sub = sub
    @placeholder = placeholder
  end
end
