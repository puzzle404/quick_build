# frozen_string_literal: true

# Card representation of a root project stage with optional collapsible
# table of sub-stages underneath. Uses qb--expandable controller for collapse.
class Constructors::Projects::Planning::StageCardComponent < ViewComponent::Base
  def initialize(project:, stage:, sub_stages:)
    @project = project
    @stage = stage.is_a?(ProjectStageDecorator) ? stage : ProjectStageDecorator.new(stage)
    @sub_stages = Array(sub_stages).map { |s| s.is_a?(ProjectStageDecorator) ? s : ProjectStageDecorator.new(s) }
  end

  attr_reader :project, :stage, :sub_stages

  def status_circle_bg
    case stage.status
    when :done  then 'color-mix(in oklab, var(--color-ok) 18%, transparent)'
    when :doing then 'color-mix(in oklab, var(--color-accent) 18%, transparent)'
    else             'var(--color-bg-sunken)'
    end
  end

  def status_circle_fg
    case stage.status
    when :done  then 'var(--color-ok)'
    when :doing then 'var(--color-accent)'
    else             'var(--color-ink-3)'
    end
  end

  def initial_open?
    stage.progress_value.positive? && stage.progress_value < 100
  end
end
