# frozen_string_literal: true

# Progress bar 4–6px with optional `plan` marker. Mirrors MBar.
class Qb::Mobile::BarComponent < ViewComponent::Base
  TONES = %i[accent ok warn bad info ink muted].freeze

  def initialize(value: 0, plan: nil, tone: :accent, height: 6, show_plan: false)
    @value = value.to_f.clamp(0, 100)
    @plan = plan && plan.to_f.clamp(0, 100)
    @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :accent
    @height = height
    @show_plan = show_plan
  end

  def call
    fill = %(<div class="m-bar-fill" data-tone="#{@tone}" style="width:#{@value}%"></div>)
    plan = @show_plan && @plan ? %(<div class="m-bar-plan" style="left:#{@plan}%"></div>) : ''
    %(<div class="m-bar" style="height:#{@height}px">#{fill}#{plan}</div>).html_safe
  end
end
