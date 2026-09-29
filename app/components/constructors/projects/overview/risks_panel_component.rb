# frozen_string_literal: true

# Alertas de la obra (rail del proyecto). Hasta que se modelen en la base se
# derivan de los datos: sobrecosto, avance por debajo del plan, entrega
# vencida y etapas atrasadas. Cada una puede traer su acción (`cta`), y la
# franja "Salud de la obra" cuenta estas mismas `items`.
class Constructors::Projects::Overview::RisksPanelComponent < ViewComponent::Base
  # Rutas y formato sin `helpers` ni `controller`: la franja de salud y el
  # contador del rail llaman a #items ANTES de renderizar, y ahí ViewComponent
  # no da view context. (qb_fmt_date_short vía ApplicationController.helpers:
  # incluirlo acá lo rompería — usa `format`, que en un ViewComponent es otro
  # método.)
  ROUTES = Rails.application.routes.url_helpers

  def initialize(project:, risks: nil, stages: nil)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @risks = risks
    @stages = stages
  end

  attr_reader :project

  def items
    return @risks if @risks

    @items ||= [ overcost, behind_plan, overdue_delivery, overdue_stages ].compact
  end

  # El rail muestra a lo sumo MAX_SHOWN (las más graves primero): sin scroll
  # interno y sin empujar el resto del tab.
  MAX_SHOWN = 3

  def shown_items
    items.sort_by { |i| i[:tone] == :bad ? 0 : 1 }.first(MAX_SHOWN)
  end

  private

  def overcost
    return unless project.health == :bad

    delta = ((project.spent.to_f / [ project.budget, 1 ].max) * 100 - 100).round
    { tone: :bad, title: "Sobrecosto detectado", body: "Gasto +#{delta}% del presupuesto.",
      cta: "Ver gastos", href: ROUTES.constructors_project_expenses_path(project) }
  end

  # Mismo número que el KPI "Avance físico" del header (progress_percent).
  def behind_plan
    real = project.progress_percent.to_i
    plan = project.planned_progress.to_i
    return unless plan - real > 8

    { tone: :warn, title: "Avance por debajo del plan", body: "Real #{real}% vs plan #{plan}%." }
  end

  def overdue_delivery
    return if project.end_date.blank? || project.end_date >= Date.current || project.completed?

    { tone: :bad, title: "Entrega vencida",
      body: "La fecha de entrega era el #{ApplicationController.helpers.qb_fmt_date_short(project.end_date)}.",
      cta: "Reprogramar entrega", href: ROUTES.edit_constructors_project_path(project),
      data: { turbo_frame: "drawer", action: "click->qb--drawer#open" } }
  end

  def overdue_stages
    return if @stages.blank?

    late = @stages.select { |s| s.end_date.present? && s.end_date < Date.current && s.progress.to_i < 100 }
    return if late.empty?

    names = late.first(3).map(&:name).join(", ")
    names += "…" if late.size > 3
    { tone: :warn, title: "#{late.size} #{late.size == 1 ? 'etapa atrasada' : 'etapas atrasadas'}", body: names }
  end
end
