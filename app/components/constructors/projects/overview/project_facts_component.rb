# frozen_string_literal: true

# "Datos de la obra" (rail del proyecto): la ficha con lo que se cargó al crear
# la obra — ubicación con mapa y compartir, cliente, estado, fechas, duración,
# presupuesto y descripción. Un dato vacío ofrece completarlo (abre la
# edición en el drawer) en lugar de un guion mudo.
class Constructors::Projects::Overview::ProjectFactsComponent < ViewComponent::Base
  def initialize(project:, weather_forecast: nil)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @weather_forecast = weather_forecast
  end

  attr_reader :project

  def can_edit?
    helpers.policy(project.object).update?
  end

  def edit_path
    helpers.edit_constructors_project_path(project)
  end

  def edit_data
    { turbo_frame: "drawer", action: "click->qb--drawer#open" }
  end

  def items
    empty = can_edit? ? edit_path : nil
    [
      { label: "Cliente", value: project.client.presence, empty_href: empty, empty_label: "Cargar cliente", empty_data: edit_data },
      { label: "Estado", value: project.status_label },
      { label: "Inicio", value: long_date(project.start_date), mono: true, empty_href: empty, empty_label: "Cargar fecha", empty_data: edit_data },
      { label: "Entrega", value: long_date(project.end_date), mono: true, empty_href: empty, empty_label: "Cargar fecha", empty_data: edit_data },
      { label: "Duración", value: project.duration_text, mono: true },
      { label: "Presupuesto", value: budget_label, mono: true, empty_href: empty, empty_label: "Cargar presupuesto", empty_data: edit_data },
      { label: "Descripción", value: project.description.presence, span: 2, empty_href: empty, empty_label: "Agregar descripción", empty_data: edit_data }
    ]
  end

  def weather
    @weather ||= Constructors::Projects::WeatherComponent.new(forecast: @weather_forecast, project: project)
  end

  private

  def long_date(date)
    return nil if date.blank?

    "#{helpers.qb_fmt_date_short(date)} #{date.year}"
  end

  def budget_label
    return nil if project.budget_cents.blank? || project.budget_cents.zero?

    helpers.qb_fmt_ars_full(project.budget_cents / 100.0)
  end
end
