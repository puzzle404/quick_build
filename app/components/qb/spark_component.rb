# frozen_string_literal: true

# Inline sparkline (SVG, no fill). Optional plan series rendered dashed.
class Qb::SparkComponent < ViewComponent::Base
  TONES = {
    accent: 'var(--color-accent)', ink: 'var(--color-ink-2)',
    ok: 'var(--color-ok)', warn: 'var(--color-warn)',
    bad: 'var(--color-bad)', info: 'var(--color-info)',
  }.freeze

  def initialize(data: [], plan: nil, w: 100, h: 24, tone: :accent)
    @data = Array(data).map(&:to_f)
    @plan = plan && plan.map(&:to_f)
    @w = w
    @h = h
    @tone = tone&.to_sym || :accent
  end

  def call
    return %(<svg width="#{@w}" height="#{@h}"></svg>).html_safe if @data.empty?
    color = TONES[@tone] || TONES[:accent]
    plan_line = @plan ? %(<polyline points="#{points(@plan)}" fill="none" stroke="var(--color-ink-4)" stroke-width="1" stroke-dasharray="2 2"/>) : ''
    last_x, last_y = last_point
    %(<svg width="#{@w}" height="#{@h}" style="overflow:visible;">#{plan_line}<polyline points="#{points(@data)}" fill="none" stroke="#{color}" stroke-width="1.4"/><circle cx="#{last_x}" cy="#{last_y}" r="2" fill="#{color}"/></svg>).html_safe
  end

  private

  def all_values
    @plan ? (@data + @plan) : @data
  end

  def points(arr)
    max_v = (all_values + [0]).max
    min_v = (all_values + [0]).min
    range = max_v - min_v
    range = 1 if range.zero?
    arr.each_with_index.map { |v, i|
      x = (i.to_f / [arr.size - 1, 1].max) * (@w - 2) + 1
      y = @h - 2 - ((v - min_v) / range) * (@h - 4)
      "#{x.round(1)},#{y.round(1)}"
    }.join(' ')
  end

  def last_point
    pts = points(@data).split(' ').last
    pts ? pts.split(',') : ['0', '0']
  end
end
