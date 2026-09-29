# frozen_string_literal: true

# Big colourful KPI card used at the top of the dashboard. Four variants —
# violet/amber/sky/emerald — mapped to the shared .qb-hero--* gradient
# classes defined in app/assets/tailwind/application.css (night-theme
# aware). Mirrors HeroCard from screens/dashboard.jsx.
class Constructors::Dashboard::HeroCardComponent < ViewComponent::Base
  VARIANTS = %i[violet amber sky emerald].freeze

  def initialize(variant:, icon:, label:, value:, hint: nil, progress: nil, cta_label:, cta_href: "#")
    @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :violet
    @icon = icon
    @label = label
    @value = value
    @hint = hint
    @progress = progress
    @cta_label = cta_label
    @cta_href = cta_href
  end

  attr_reader :icon, :label, :value, :hint, :progress, :cta_label, :cta_href

  def hero_class
    "qb-hero--#{@variant}"
  end
end
