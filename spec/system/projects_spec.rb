require 'rails_helper'

RSpec.describe "Project management", type: :system do
  let(:constructor) { create(:user, :constructor) }

  it "allows a constructor to create a project" do
    sign_in_user(constructor)
    visit new_constructors_project_path
    # Wizard form uses Spanish labels and field IDs derived from project[*].
    fill_in "project[name]",       with: "My Project"
    fill_in "project[location]",   with: "Town"
    fill_in "project[start_date]", with: Date.today
    fill_in "project[end_date]",   with: Date.today + 1
    click_button "Crear proyecto"
    expect(page).to have_content("My Project")
  end

  it "captures description and address in the first wizard step" do
    sign_in_user(constructor)
    visit new_constructors_project_path

    fill_in "project[name]",        with: "Obra Centro"
    fill_in "project[location]",    with: "Av. Colón 1234, Mendoza"
    fill_in "project[description]", with: "Refacción integral del hall"
    click_button "Crear proyecto"

    project = constructor.owned_projects.order(:created_at).last
    expect(project.location).to eq("Av. Colón 1234, Mendoza")
    expect(project.description).to eq("Refacción integral del hall")
  end

  it "arma la obra en una sola pantalla, con mapa y sin pasos intermedios" do
    sign_in_user(constructor)
    visit new_constructors_project_path

    # El picker Leaflet y el domicilio viven en el mismo formulario.
    expect(page).to have_css("#project-map")
    expect(page).to have_content("Crear una obra")
    # Fuera del alta: los planos se cargan desde Documentos y la plantilla de
    # etapas se aplica desde el header del proyecto.
    expect(page).to have_no_content("Planos y ubicación")
    expect(page).to have_no_field("project[document_files][]")
    expect(page).to have_no_button("Continuar")
  end

  it "allows a constructor to edit a project" do
    project = create(:project, owner: constructor, name: "Obra Norte")

    sign_in_user(constructor)
    visit edit_constructors_project_path(project)

    fill_in "Name", with: "Obra Norte Renovada"
    select "In progress", from: "Status"
    click_button "Actualizar obra"

    expect(page).to have_content("Obra actualizada correctamente.")
    expect(page).to have_content("Obra Norte Renovada")
  end
end
