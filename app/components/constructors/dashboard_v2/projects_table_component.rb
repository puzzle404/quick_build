# frozen_string_literal: true

# Dense table of active projects: code, name+client, status, progress vs plan
# (with bar), S-curve sparkline, budget, team, stages, due date.
class Constructors::DashboardV2::ProjectsTableComponent < ViewComponent::Base
  HEADERS = ['', 'Obra', 'Estado', 'Avance', 'Curva S', 'Presupuesto', 'Equipo', 'Etapas', 'Vence', ''].freeze

  def initialize(rows:)
    @rows = rows.map { |r| r.is_a?(ProjectDecorator) ? r : ProjectDecorator.new(r) }
  end

  attr_reader :rows

  def status_label(p)
    p.status_label
  end

  def status_tone(p)
    case p.status.to_s
    when 'in_progress' then :info
    when 'completed'   then :ok
    else :muted
    end
  end

  def used_pct(p)
    return 0 if p.budget.to_i.zero?
    ((p.spent.to_f / p.budget) * 100).round
  end

  def bar_tone(p)
    case p.health
    when :bad  then :bad
    when :warn then :warn
    else :accent
    end
  end

  def th_align(idx)
    (3..8).cover?(idx) ? 'right' : 'left'
  end
end
