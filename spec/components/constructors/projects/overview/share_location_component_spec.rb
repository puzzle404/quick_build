# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::Overview::ShareLocationComponent, type: :component do
  it "comparte el domicilio escrito y el link al punto del mapa" do
    project = build(:project, name: "Torre Norte", location: "Av. Colón 1234, Mendoza", latitude: -32.89, longitude: -68.84)
    component = described_class.new(project: project)

    expect(component.share_text).to eq(
      "Obra: Torre Norte\nDomicilio: Av. Colón 1234, Mendoza\n" \
      "Mapa: https://www.google.com/maps/search/?api=1&query=-32.890000%2C-68.840000"
    )
    render_inline(component)
    expect(page).to have_button("Compartir ubicación")
    expect(page).to have_link("WhatsApp", href: /\Ahttps:\/\/wa\.me\/\?text=Obra%3A%20Torre%20Norte/)
  end

  it "sin coordenadas, el link busca el domicilio" do
    project = build(:project, location: "Ruta 40 km 3", latitude: nil, longitude: nil)

    expect(described_class.new(project: project).maps_url).to end_with("query=Ruta%2040%20km%203")
  end

  it "no se renderiza si no hay ni domicilio ni coordenadas" do
    project = build(:project, location: nil, latitude: nil, longitude: nil)

    expect(render_inline(described_class.new(project: project)).to_html).to be_blank
  end
end
