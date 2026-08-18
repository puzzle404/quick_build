# frozen_string_literal: true

# Three-segment bar: spent (solid accent) + committed (mid) + remaining (track).
class Qb::StackedBarComponent < ViewComponent::Base
  def initialize(spent:, committed:, total:, height: 6)
    @spent = spent.to_f
    @committed = committed.to_f
    @total = total.to_f
    @height = height
  end

  def call
    s = @total.positive? ? (@spent / @total * 100).round : 0
    c = @total.positive? ? (@committed / @total * 100).round : 0
    %(<div style="position:relative;width:100%;height:#{@height}px;background:var(--color-line);border-radius:999px;overflow:hidden;display:flex;"><div style="width:#{s}%;background:var(--color-accent);"></div><div style="width:#{c}%;background:color-mix(in oklab, var(--color-accent) 40%, var(--color-line));"></div></div>).html_safe
  end
end
