# frozen_string_literal: true

# Big colourful KPI card used at the top of the dashboard. Four variants —
# violet/amber/sky/emerald — each with its own gradient. Optional progress bar
# and CTA button. Mirrors HeroCard from screens/dashboard.jsx.
class Constructors::DashboardV2::HeroCardComponent < ViewComponent::Base
  THEMES = {
    violet:  { bg: 'linear-gradient(135deg, oklch(42% 0.22 295) 0%, oklch(55% 0.24 285) 100%)', accent: 'oklch(92% 0.08 295)' },
    amber:   { bg: 'linear-gradient(135deg, oklch(62% 0.22 45)  0%, oklch(72% 0.21 55)  100%)', accent: 'oklch(96% 0.08 70)'  },
    sky:     { bg: 'linear-gradient(135deg, oklch(50% 0.20 250) 0%, oklch(62% 0.22 230) 100%)', accent: 'oklch(94% 0.08 230)' },
    emerald: { bg: 'linear-gradient(135deg, oklch(45% 0.15 165) 0%, oklch(58% 0.15 155) 100%)', accent: 'oklch(94% 0.10 165)' },
  }.freeze

  def initialize(variant:, icon:, label:, value:, hint: nil, progress: nil, cta_label:, cta_href: '#')
    @variant = variant&.to_sym || :violet
    @icon = icon
    @label = label
    @value = value
    @hint = hint
    @progress = progress
    @cta_label = cta_label
    @cta_href = cta_href
  end

  attr_reader :icon, :label, :value, :hint, :progress, :cta_label, :cta_href

  def theme
    THEMES[@variant] || THEMES[:violet]
  end
end
