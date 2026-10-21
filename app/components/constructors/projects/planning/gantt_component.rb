# frozen_string_literal: true

# Two-column Gantt: left WBS list, right time bars on a calendar scale derived
# from the project's date range.
class Constructors::Projects::Planning::GanttComponent < ViewComponent::Base
  MONTHS_ES = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze

  Row = Struct.new(:stage, :depth, keyword_init: true)

  def initialize(project:, root_stages:, expense_totals: nil, today: Date.current)
    @project = project
    @root_stages = Array(root_stages)
    @injected_totals = expense_totals
    @today = today
  end

  attr_reader :project

  # Gasto real de la fila, en centavos, con roll-up de sub-etapas en las filas
  # raíz. Misma fuente que las cards (Expenses vía Projects::SpendSummary): la
  # columna project_stages.spent_cents es data de seed que nadie escribe.
  def spent_cents_for(row)
    ids = [ row.stage.id ]
    ids += row.stage.object.sub_stages.map(&:id) if row.depth.zero?
    ids.sum { |id| expense_totals[id].to_i }
  end

  def spent_pct_for(row)
    budget = row.stage.budget
    return 0 if budget.zero?
    ((spent_cents_for(row).to_f / budget) * 100).round
  end

  def show_spend?(row)
    row.stage.budget.positive? || spent_cents_for(row).positive?
  end

  # Memoized: `rows` is read repeatedly (date_range, total_days, months_grid,
  # today_pct + the template), and `sub_stages` is sorted in Ruby on the
  # eager-loaded association — using `.order` here would fire one query per
  # root every time rows is recomputed (the planning N+1).
  def rows
    @rows ||= begin
      out = []
      @root_stages.each do |root|
        out << Row.new(stage: ProjectStageDecorator.new(root), depth: 0)
        root.sub_stages.sort_by { |s| [ s.position.to_i, s.name.to_s ] }.each do |sub|
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
        [ Date.current.beginning_of_month, (Date.current >> 6).end_of_month ]
      else
        [ starts.min.beginning_of_month, [ ends.max, Date.current ].compact.max.end_of_month ]
      end
    end
  end

  def total_days
    rs = date_range
    [ (rs[1] - rs[0]).to_i, 1 ].max
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
    return "var(--color-ok)"      if stage.status == :done
    return "var(--color-line-2)"  if stage.status == :pending
    return "var(--color-accent)"  if stage.progress_value >= 60
    "var(--color-warn)"
  end

  def today_pct
    pct_at(@today)
  end

  private

  # Precomputado por el controller (@stage_expense_totals) ⇒ 0 queries. Sin
  # inyección cae a UNA query para todo el proyecto, nunca una por fila.
  def expense_totals
    @expense_totals ||= @injected_totals || Projects::SpendSummary.new(project_record).by_stage
  end

  def project_record
    project.respond_to?(:object) ? project.object : project
  end
end
