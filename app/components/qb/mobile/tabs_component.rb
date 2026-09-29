# frozen_string_literal: true

# Underline tabs (replaces the old chip pattern). `options` is an array of
# hashes: `{ key:, label:, count:, href:, icon: }`.
class Qb::Mobile::TabsComponent < ViewComponent::Base
  def initialize(options:, value: nil)
    @options = Array(options)
    @value = value
  end
end
