# frozen_string_literal: true

# iOS-style segmented control. `options` is an array of `{ key:, label:, href: }`
# hashes (href optional). Selection is identified by `value`.
class Qb::Mobile::SegmentedComponent < ViewComponent::Base
  def initialize(options:, value: nil, name: nil)
    @options = Array(options)
    @value = value
    @name = name
  end
end
