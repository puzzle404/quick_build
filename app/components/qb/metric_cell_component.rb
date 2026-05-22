# frozen_string_literal: true

# Mono-numeral metric cell used in 4/5-column strips at the top of pages.
class Qb::MetricCellComponent < ViewComponent::Base
  TONE_COLOR = {
    ok:   'var(--color-ok)',
    warn: 'var(--color-warn)',
    bad:  'var(--color-bad)',
    info: 'var(--color-info)',
  }.freeze

  renders_one :extra

  def initialize(label:, value:, hint: nil, tone: nil, highlight: false)
    @label = label
    @value = value
    @hint = hint
    @tone = tone&.to_sym
    @highlight = highlight
  end

  attr_reader :label, :value, :hint, :highlight

  def value_color
    TONE_COLOR[@tone] || 'var(--color-ink)'
  end

  def hint_color
    TONE_COLOR[@tone] || 'var(--color-ink-3)'
  end
end
