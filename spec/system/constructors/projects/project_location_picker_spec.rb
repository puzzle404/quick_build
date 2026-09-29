# frozen_string_literal: true

require "rails_helper"

# Dirección + ubicación de la obra con Google Maps (stub en
# spec/support/google_maps_stub.rb): sugerencias debajo del campo, pin fijo al
# centro del mapa, y mover el mapa NUNCA cambia la dirección escrita.
RSpec.describe "Project location picker", type: :system, js: true, google_maps: true do
  let(:constructor) { create(:user, :constructor) }

  def hidden_value(name)
    find("input[name='project[#{name}]']", visible: false).value.to_f
  end

  before do
    sign_in_user(constructor)
    stub_google_maps!
  end

  it "elegir una sugerencia completa la dirección y centra el mapa; moverlo no la cambia" do
    visit new_constructors_project_path
    expect(page).to have_no_css("#project-map", visible: :visible) # el mapa aparece recién al elegir

    fill_in "project[location]", with: "Av Colon 1234"
    find(".qb-addr-option", text: "Avenida Colón 1234", wait: 5)
    expect(page).to have_css(".qb-addr-suggestions", text: "Sugerencias de Google")
    find(".qb-addr-option", text: "Avenida Colón 1234").click

    expect(page).to have_field("project[location]", with: "Av. Colón 1234, M5500 Mendoza, Argentina", wait: 5)
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)
    expect(hidden_value("latitude")).to be_within(0.0001).of(-32.8895)

    # El usuario agrega un dato propio y después ajusta el pin ~500 m.
    fill_in "project[location]", with: "Av. Colón 1234, Mendoza · Lote 3"
    page.execute_script("window.__gmMoveMap(-32.8940, -68.8458)")

    expect(page).to have_field("project[location]", with: "Av. Colón 1234, Mendoza · Lote 3")
    expect(page).to have_content("El pin quedó a 500 m de la dirección")
    expect(hidden_value("latitude")).to be_within(0.0001).of(-32.8940)

    fill_in "project[name]", with: "Obra con pin"
    click_button "Crear proyecto"

    project = constructor.owned_projects.order(:created_at).last
    expect(project).to have_attributes(name: "Obra con pin", location: "Av. Colón 1234, Mendoza · Lote 3")
    expect(project.latitude).to be_within(0.0001).of(-32.8940)
  end

  it "Enter elige la sugerencia resaltada en vez de mandar el form" do
    visit new_constructors_project_path

    field = find_field("project[location]")
    field.fill_in(with: "Av Colon")
    find(".qb-addr-option", wait: 5)
    field.send_keys(:down, :enter)

    expect(page).to have_field("project[location]", with: "Av. Colón 1234, M5500 Mendoza, Argentina", wait: 5)
    expect(page).to have_current_path(new_constructors_project_path)
  end

  it "una obra ya ubicada abre el mapa en su punto, sin tocar la dirección" do
    project = create(:project, owner: constructor, location: "Obrador km 3", latitude: -32.8895, longitude: -68.8458)

    visit edit_constructors_project_path(project)

    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)
    expect(page).to have_field("project[location]", with: "Obrador km 3")
    expect(hidden_value("latitude")).to be_within(0.0001).of(-32.8895)
  end

  it "sin dirección exacta se puede marcar la obra directamente en el mapa" do
    visit new_constructors_project_path

    click_button "¿No encontrás la dirección? Marcá la obra en el mapa"
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)
    page.execute_script("window.__gmMoveMap(-33.0, -68.9)")

    expect(hidden_value("latitude")).to be_within(0.0001).of(-33.0)
    expect(page).to have_field("project[location]", with: "")
  end
end
