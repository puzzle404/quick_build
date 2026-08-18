# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::Overview::MiniMapComponent, type: :component do
  it "monta un Leaflet real cuando la obra tiene coordenadas" do
    render_inline(described_class.new(lat: -32.8895, lng: -68.8458))

    node = page.find("[data-controller='qb--mini-map']")
    expect(node["data-qb--mini-map-lat-value"]).to eq("-32.8895")
    expect(node["data-qb--mini-map-lng-value"]).to eq("-68.8458")
    expect(page.text).to include("-32.8895, -68.8458")
  end

  it "linkea a OpenStreetMap con el marcador en la obra" do
    render_inline(described_class.new(lat: -32.8895, lng: -68.8458))

    link = page.find_link("Ver en mapa ↗")
    expect(link["href"]).to start_with("https://www.openstreetmap.org/?mlat=-32.889500&mlon=-68.845800")
    expect(link["target"]).to eq("_blank")
  end

  it "sin coordenadas muestra el vacío con acceso a ubicar la obra, y ningún mapa" do
    project = build_stubbed(:project, latitude: nil, longitude: nil)
    render_inline(described_class.new(project: project))

    expect(page.text).to include("Esta obra todavía no está ubicada en el mapa.")
    expect(page).to have_link("Ubicar en el mapa", href: "/constructors/projects/#{project.id}/edit")
    expect(page).to have_no_css("[data-controller='qb--mini-map']")
  end
end
