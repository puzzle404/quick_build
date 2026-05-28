# frozen_string_literal: true

# Two-column Gantt: left WBS list, right time bars on a calendar scale derived
# from the project's date range.
class Constructors::Projects::Planning::GanttComponent < ViewComponent::Base
  MONTHS_ES = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze

  Row = Struct.new(:stage, :depth, keyword_init: true)

  def initialize(project:, root_stages:, today: Date.current)
    @project = project
    @root_stages = Array(root_stages)
    @today = today
  end

  attr_reader :project

  # Memoized: `rows` is read repeatedly (date_range, total_days, months_grid,
  # today_pct + the template), and `sub_stages` is sorted in Ruby on the
  # eager-loaded association — using `.order` here would fire one query per
  # root every time rows is recomputed (the planning N+1).
  def rows
    @rows ||= begin
      out = []
      @root_stages.each do |root|
        out << Row.new(stage: ProjectStageDecorator.new(root), depth: 0)
        root.sub_stages.sort_by { |s| [s.position.to_i, s.name.to_s] }.each do |sub|
          out << Row.new(stage: ProjectStageDecorator.new(sub), depth: 1)
        end
      end
      out
    end
  end

  # Derive the chart's time window from the actual stages. Both bounds are
  # Date values so subtraction stays integer-days (TimeWithZone would break
  # `(rs[1] - rs[0]).to_i` with "can't convert Date into an exact number").
  def date_range
    @date_range ||= begin
      starts = rows.map { |r| r.stage.start_date }.compact
      ends   = rows.map { |r| r.stage.end_date }.compact
      if starts.empty?
        [Date.current.beginning_of_month, (Date.current >> 6).end_of_month]
      else
        [starts.min.beginning_of_month, [ends.max, Date.current].compact.max.end_of_month]
      end
    end
  end

  def total_days
    rs = date_range
    [(rs[1] - rs[0]).to_i, 1].max
  end

  def pct_at(date)
    return 0 if date.blank?
    rs = date_range
    ((date - rs[0]).to_f / total_days * 100).round(2)
  end

  def months_grid
    rs = date_range
    months = []
    cursor = rs[0].beginning_of_month
    while cursor <= rs[1]
      months << cursor
      cursor = (cursor >> 1)
    end
    months
  end

  def month_label(date)
    MONTHS_ES[date.month - 1]
  end

  def bar_color(stage)
    return 'var(--color-ok)'      if stage.status == :done
    return 'var(--color-line-2)'  if stage.status == :pending
    return 'var(--color-accent)'  if stage.progress_value >= 60
    'var(--color-warn)'
  end

  def today_pct
    pct_at(@today)
  end
end
