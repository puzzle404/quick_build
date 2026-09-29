# frozen_string_literal: true

# "Compartir ubicación" de la obra: domicilio + link al mapa, listo para
# mandar por WhatsApp o pegar donde haga falta.
#
# Manda el DOMICILIO escrito por el usuario (es el dato que prepondera); el
# link lleva al punto marcado en el mapa y, si la obra no está ubicada, a una
# búsqueda del domicilio en Google Maps.
class Constructors::Projects::Overview::ShareLocationComponent < ViewComponent::Base
  def initialize(project:)
    @project = project
  end

  def render?
    address.present? || located?
  end

  def address
    @project.location.to_s.strip.presence
  end

  def located?
    @project.latitude.present? && @project.longitude.present?
  end

  def maps_url
    query = located? ? "#{coord(@project.latitude)},#{coord(@project.longitude)}" : address
    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(query)}"
  end

  def share_text
    [ "Obra: #{@project.name}", ("Domicilio: #{address}" if address), "Mapa: #{maps_url}" ].compact.join("\n")
  end

  def whatsapp_url
    "https://wa.me/?text=#{ERB::Util.url_encode(share_text)}"
  end

  private

  def coord(value)
    sprintf("%.6f", value)
  end
end
