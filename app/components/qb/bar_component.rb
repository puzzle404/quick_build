# frozen_string_literal: true

# Horizontal progress bar with optional plan marker.
class Qb::BarComponent < ViewComponent::Base
  TONES = {
    accent: 'var(--color-accent)',
    ok:     'var(--color-ok)',
    warn:   'var(--color-warn)',
    bad:    'var(--color-bad)',
    info:   'var(--color-info)',
    ink:    'var(--color-ink-2)',
    muted:  'var(--color-ink-4)',
  }.freeze

  def initialize(value: 0, plan: nil, tone: :accent, height: 6, show_plan: false)
    @value = clamp(value)
    @plan = plan
    @tone = tone&.to_sym || :accent
    @height = height
    @show_plan = show_plan
  end

  def call
    color = TONES[@tone] || TONES[:accent]
    bar = %(<div style="position:absolute;inset:0;width:#{@value}%;background:#{color};border-radius:999px;transition:width .3s;"></div>)
    plan_marker =
      if @show_plan && @plan
        %(<div style="position:absolute;top:-2px;bottom:-2px;left:#{clamp(@plan)}%;width:1px;background:var(--color-ink-2);"></div>)
      end
    %(<div style="position:relative;width:100%;height:#{@height}px;background:var(--color-line);border-radius:999px;overflow:hidden;">#{bar}#{plan_marker}</div>).html_safe
  end

  private

  # Returns an integer percent (0..100) so generated CSS reads "42%" not "42.0%".
  def clamp(v)
    return 0 if v.nil?
    [[v.to_f, 0].max, 100].min.round
  end
end
