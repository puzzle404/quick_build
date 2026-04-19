# frozen_string_literal: true

# Dense KPI block (used in the 4-column strip below the hero cards). Includes
# label, value, hint and an inline sparkline.
class Constructors::DashboardV2::KpiBlockComponent < ViewComponent::Base
  def initialize(label:, value:, hint: nil, tone: nil, data: nil, suffix: nil, highlight: false)
    @label = label
    @value = value
    @hint = hint
    @tone = tone&.to_sym
    @data = data
    @suffix = suffix
    @highlight = highlight
  end

  attr_reader :label, :value, :hint, :tone, :data, :suffix, :highlight

  def hint_color
    case tone
    when :ok    then 'var(--color-ok)'
    when :warn  then 'var(--color-warn)'
    when :bad   then 'var(--color-bad)'
    when :info  then 'var(--color-info)'
    when :accent then 'var(--color-accent)'
    else 'var(--color-ink-3)'
    end
  end

  def spark_tone
    [:warn, :ok, :info].include?(tone) ? tone : :accent
  end
end
