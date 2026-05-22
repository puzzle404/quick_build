# frozen_string_literal: true

# Visual placeholder for the project's geo location: a CSS grid background with
# a pulsing dot. We render coords if known. Real Leaflet integration lives on
# the project edit page (project_map_controller.js).
class Constructors::Projects::Overview::MiniMapComponent < ViewComponent::Base
  def initialize(lat:, lng:)
    @lat = lat
    @lng = lng
  end

  attr_reader :lat, :lng

  def coords_label
    return 'Ubicación pendiente' if lat.blank? || lng.blank?
    # Use sprintf — `format` in a ViewComponent collides with ActionView#format (0-arg).
    "#{sprintf('%.4f', lat)}, #{sprintf('%.4f', lng)}"
  end
end
