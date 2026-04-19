# frozen_string_literal: true

# Visual placeholder for the project's geo location: a CSS grid background with
# a pulsing dot. We render coords if known. Real Leaflet integration lives on
# the project edit page (project_map_controller.js).
class Constructors::ProjectsV2::Overview::MiniMapComponent < ViewComponent::Base
  def initialize(lat:, lng:)
    @lat = lat
    @lng = lng
  end

  attr_reader :lat, :lng

  def coords_label
    return 'Ubicación pendiente' if lat.blank? || lng.blank?
    "#{format('%.4f', lat)}, #{format('%.4f', lng)}"
  end
end
