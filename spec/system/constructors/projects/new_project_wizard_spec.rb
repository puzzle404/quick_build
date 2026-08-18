# frozen_string_literal: true

require "rails_helper"

# JS (Cuprite): el picker Leaflet (project-map) sólo se inicializa con Stimulus,
# así que en rack_test el mapa no arranca.
#
# El alta dejó de ser un wizard multi-paso: la plantilla de etapas se aplica
# desde el header del proyecto (elegirla antes de crear la obra era pedirle al
# usuario que decidiera algo que todavía no sabe), y con ese paso afuera el
# formulario entra en una sola pantalla.
RSpec.describe "New project form", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }

  it "muestra el picker Leaflet y el formulario completo en una sola pantalla" do
    sign_in_user(constructor)
    visit new_constructors_project_path

    expect(page).to have_content("Crear una obra")

    expect(page).to have_css("#project-map.leaflet-container", wait: 5)
    expect(page).to have_css(".leaflet-control-geocoder", wait: 5)
    expect(page).to have_css("#project-map .leaflet-marker-icon", wait: 5)

    # Todos los campos son alcanzables sin pasos intermedios.
    expect(page).to have_field("project[location]")
    expect(page).to have_field("project[description]")
    expect(page).to have_field("project[budget_pesos]")
    expect(page).to have_button("Crear proyecto")

    # La plantilla salió del alta: se aplica desde el proyecto.
    expect(page).to have_no_content("Plantilla base (3 grupos)")
    expect(page).to have_no_button("Continuar")
  end

  it "guarda la dirección y las coordenadas del marcador" do
    sign_in_user(constructor)
    visit new_constructors_project_path

    expect(page).to have_css("#project-map.leaflet-container", wait: 5)

    fill_in "project[name]",        with: "Obra con mapa"
    fill_in "project[location]",    with: "Av. Colón 1234, Mendoza"
    fill_in "project[description]", with: "Refacción del hall"

    # El controller escribe lat/lng en los hidden fields al mover el marcador.
    page.execute_script(<<~JS)
      document.querySelector("input[name='project[latitude]']").value  = "-32.8895"
      document.querySelector("input[name='project[longitude]']").value = "-68.8458"
    JS

    click_button "Crear proyecto"

    project = constructor.owned_projects.order(:created_at).last
    expect(project.location).to eq("Av. Colón 1234, Mendoza")
    expect(project.description).to eq("Refacción del hall")
    expect(project.latitude).to be_within(0.001).of(-32.8895)
    expect(project.longitude).to be_within(0.001).of(-68.8458)
  end

  it "acepta el presupuesto en pesos con formato local" do
    sign_in_user(constructor)
    visit new_constructors_project_path

    fill_in "project[name]", with: "Obra con presupuesto"
    fill_in "project[budget_pesos]", with: "1.500.000,50"
    click_button "Crear proyecto"

    project = constructor.owned_projects.order(:created_at).last
    expect(project.budget_cents).to eq(150_000_050)
  end
end
