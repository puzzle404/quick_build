# frozen_string_literal: true

# Visual mini-map of all stages: a 14-column grid where each cell colour
# encodes the stage's health/progress.
class Constructors::ProjectsV2::Overview::StageHeatmapComponent < ViewComponent::Base
  def initialize(stages:)
    @stages = Array(stages)
  end

  attr_reader :stages

  def cell_color(s)
    p = s.try(:progress).to_i
    return 'var(--color-ok)'      if p >= 100
    return 'var(--color-line-2)'  if p.zero?
    return 'var(--color-accent)'  if p > 60
    'var(--color-warn)'
  end

  def cell_opacity(s)
    p = s.try(:progress).to_i
    return 0.4 if p.zero?
    [0.3, p / 100.0].max.round(2)
  end

  def short_code(s, idx)
    s.try(:code).presence || (idx + 1).to_s
  end
end
