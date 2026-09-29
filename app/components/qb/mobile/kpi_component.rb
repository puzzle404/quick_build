# frozen_string_literal: true

# Hero KPI card. `gradient` (:violet|:amber|:sky|:emerald) paints the card with
# a coloured background; nil keeps the neutral raised card.
class Qb::Mobile::KpiComponent < ViewComponent::Base
  GRADIENTS = %i[violet amber sky emerald].freeze
  DELTA_TONES = %i[ok warn muted].freeze

  def initialize(label:, value:, delta: nil, delta_tone: :muted, icon: nil, gradient: nil, hint: nil)
    @label = label
    @value = value
    @delta = delta
    @delta_tone = DELTA_TONES.include?(delta_tone&.to_sym) ? delta_tone.to_sym : :muted
    @icon = icon
    @gradient = GRADIENTS.include?(gradient&.to_sym) ? gradient.to_sym : nil
    @hint = hint
  end
end
