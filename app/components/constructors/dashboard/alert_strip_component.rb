# frozen_string_literal: true

# List of urgent items needing attention. Falls back to deriving alerts from
# project health when no explicit alerts source is provided.
class Constructors::Dashboard::AlertStripComponent < ViewComponent::Base
  def initialize(projects: [], explicit: nil)
    @projects = projects
    @explicit = explicit
  end

  attr_reader :explicit

  def alerts
    return @explicit if @explicit
    @projects
      .select { |p| p.health != :ok && p.status.to_s != 'completed' }
      .first(3)
      .map { |p| build_alert_for(p) }
  end

  private

  def build_alert_for(p)
    if p.health == :bad
      delta = ((p.spent.to_f / [p.budget, 1].max) * 100 - 100).round
      { tone: :bad, project: "#{p.code} · #{p.name}", message: "Sobrecosto proyectado +#{delta}% vs presupuesto", when: 'Hoy' }
    else
      delta = (p.planned_progress - p.progress)
      { tone: :warn, project: "#{p.code} · #{p.name}", message: "Avance físico #{delta} pts por debajo del plan", when: 'Hoy' }
    end
  end
end
