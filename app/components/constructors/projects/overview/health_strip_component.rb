# frozen_string_literal: true

# Franja "Salud de la obra" arriba del rail del proyecto, siempre a la vista
# (fuera de los tabs): avance real vs plan, riesgos abiertos y el próximo
# vencimiento. Resume lo que el resto del rail detalla.
class Constructors::Projects::Overview::HealthStripComponent < ViewComponent::Base
  def initialize(project:, stages:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @stages = stages
  end

  attr_reader :project

  # Misma fuente que "Avance físico" del header (progress_percent), para que
  # la franja y el KPI de arriba nunca muestren números distintos.
  def progress
    project.progress_percent.to_i
  end

  def delta
    progress - project.planned_progress.to_i
  end

  def delta_label
    delta.positive? ? "+#{delta}" : delta.to_s.sub("-", "−")
  end

  def delta_tone
    return "var(--color-ok)" if delta >= 0
    delta < -8 ? "var(--color-bad)" : "var(--color-warn)"
  end

  def risks_count
    @risks_count ||= Constructors::Projects::Overview::RisksPanelComponent.new(project: project, stages: @stages).items.size
  end

  def next_stage
    @next_stage ||= Constructors::Projects::Overview::UpcomingDeadlinesComponent.pending_by_due(@stages).first
  end

  def next_overdue?
    next_stage && next_stage.end_date < Date.current
  end
end
