# frozen_string_literal: true

# Mini-mapa de la obra para el rail de seguimiento. Es un Google Maps real de
# solo lectura (sin drag ni zoom, para no secuestrar el scroll del rail).
#
# Cuando la obra no tiene coordenadas mostramos un vacío honesto con acceso a
# ubicarla: hoy la mayoría de los proyectos está en ese caso y dibujar algo que
# parezca un mapa sería mentir sobre dónde está la obra.
class Constructors::Projects::Overview::MiniMapComponent < ViewComponent::Base
  DEFAULT_ZOOM = 15

  # Acepta `project:` (preferido: habilita el CTA a editar) o `lat:`/`lng:`
  # sueltos, que es como lo llama hoy la vista de proyecto.
  def initialize(lat: nil, lng: nil, project: nil, zoom: DEFAULT_ZOOM)
    @project = project
    @lat = project ? project.latitude : lat
    @lng = project ? project.longitude : lng
    @zoom = zoom
  end

  attr_reader :lat, :lng, :zoom

  def located?
    lat.present? && lng.present?
  end

  def coords_label
    return "Ubicación pendiente" unless located?

    # sprintf y no `format`: en un ViewComponent `format` es ActionView#format.
    "#{sprintf('%.4f', lat)}, #{sprintf('%.4f', lng)}"
  end

  # Link a Google Maps con el punto de la obra.
  def maps_url
    return nil unless located?

    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode("#{coord(lat)},#{coord(lng)}")}"
  end

  # Path para ir a ubicar la obra. Si no nos pasaron el proyecto lo tomamos del
  # contexto del layout de constructor, que ya lo expone como helper.
  def edit_path
    target = @project || current_qb_project
    return nil if target.blank?

    edit_constructors_project_path(target)
  end

  private

  def current_qb_project
    return nil unless helpers.respond_to?(:current_qb_project)

    helpers.current_qb_project
  end

  def coord(value)
    sprintf("%.6f", value)
  end
end
