# frozen_string_literal: true

# Tarjeta "Datos de la obra" del panel del proyecto: mapa con la ubicación
# (compartir / abrir en Google Maps), la dirección escrita —el dato que manda
# al compartir— y los tres datos que más se consultan: cliente, plazo y
# presupuesto. Lo que falta ofrece cargarlo (edición en el drawer).
class Constructors::Projects::Overview::ObraCardComponent < ViewComponent::Base
  MAP_ZOOM = 15

  def initialize(project:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
  end

  attr_reader :project

  def located?
    project.latitude.present? && project.longitude.present?
  end

  def address
    project.location.to_s.strip.presence
  end

  def can_edit?
    helpers.policy(project.object).update?
  end

  def edit_path
    helpers.edit_constructors_project_path(project)
  end

  def drawer_data
    { turbo_frame: "drawer", action: "click->qb--drawer#open" }
  end

  # Link al punto marcado; sin coordenadas, búsqueda del domicilio.
  def maps_url
    return nil unless located? || address

    query = located? ? "#{coord(project.latitude)},#{coord(project.longitude)}" : address
    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(query)}"
  end

  # Manda el domicilio escrito (es lo que prepondera) y el link al mapa.
  def share_text
    [ "Obra: #{project.name}", ("Domicilio: #{address}" if address), ("Mapa: #{maps_url}" if maps_url) ].compact.join("\n")
  end

  def client
    project.client.presence
  end

  def facts
    [
      { label: "Plazo", value: term_label, mono: true },
      { label: "Presupuesto", value: budget_label, mono: true }
    ]
  end

  private

  def term_label
    return nil unless project.start_date || project.end_date

    [ project.start_date, project.end_date ].map { |d| d ? helpers.qb_fmt_date_short(d) : "?" }.join(" → ")
  end

  def budget_label
    project.budget_cents.to_i.positive? ? helpers.qb_fmt_cents(project.budget_cents) : nil
  end

  def coord(value)
    sprintf("%.6f", value)
  end
end
