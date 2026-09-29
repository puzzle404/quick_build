# frozen_string_literal: true

# "Próximos vencimientos" del rail del proyecto: las etapas principales sin
# terminar ordenadas por fecha de fin — las vencidas quedan primero y en rojo.
# Recibe las raíces ya cargadas (projects#show), así que no suma queries.
# `limit: nil` las lista todas (el rail las muestra en una caja con scroll).
class Constructors::Projects::Overview::UpcomingDeadlinesComponent < ViewComponent::Base
  DEFAULT_LIMIT = 3

  def self.pending_by_due(stages)
    stages.select { |s| s.end_date.present? && s.progress.to_i < 100 }.sort_by { |s| [ s.end_date, s.position.to_i ] }
  end

  def initialize(project:, stages:, limit: DEFAULT_LIMIT)
    @project = project
    pending = self.class.pending_by_due(stages)
    @stages = limit ? pending.first(limit) : pending
  end

  attr_reader :project, :stages

  def overdue?(stage)
    stage.end_date < Date.current
  end

  def due_label(stage)
    days = (stage.end_date - Date.current).to_i
    return "vencida hace #{-days}d" if days.negative?
    return "vence hoy" if days.zero?

    days <= 14 ? "en #{days}d" : helpers.qb_fmt_date_short(stage.end_date)
  end
end
