# frozen_string_literal: true

# Panel de notificaciones compartido: lo usa el dropdown de la campana en el
# topbar (desktop) y el sheet de alertas en mobile. Deriva las alertas de los
# proyectos decorados con la misma regla que
# Constructors::Dashboard::AlertStripComponent (salud != :ok en proyectos no
# finalizados), y linkea cada alerta a su proyecto.
class Qb::Layout::AlertsPanelComponent < ViewComponent::Base
  MAX_ALERTS = 6

  def initialize(projects: [])
    @projects = Array(projects)
  end

  def alerts
    @alerts ||= @projects
                .select { |p| p.health != :ok && p.status.to_s != "completed" }
                .first(MAX_ALERTS)
                .map { |p| build_alert_for(p) }
  end

  private

  def build_alert_for(p)
    if p.health == :bad
      delta = ((p.spent.to_f / [ p.budget, 1 ].max) * 100 - 100).round
      { tone: :bad, project: p, label: "#{p.code} · #{p.name}",
        message: "Sobrecosto proyectado +#{delta}% vs presupuesto", when: "Hoy" }
    else
      delta = (p.planned_progress - p.progress)
      { tone: :warn, project: p, label: "#{p.code} · #{p.name}",
        message: "Avance físico #{delta} pts por debajo del plan", when: "Hoy" }
    end
  end
end
