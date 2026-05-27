# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning stage drawer", type: :system do
  it "abre el detalle de la etapa en el drawer y permite registrar un gasto" do
    owner   = create(:user, :constructor)
    project = create(:project, owner: owner)
    stage   = create(:project_stage, project: project, name: "Fundaciones",
                                     start_date: Date.current, end_date: Date.current + 10)

    sign_in_user(owner)
    visit constructors_project_planning_path(project)

    # El drawer compartido existe en el DOM pero comienza oculto
    expect(page).to have_css("[data-qb--drawer-target='dialog']", visible: :all)

    # Clickear el link de la etapa: carga el detalle en el frame y abre el drawer
    click_on "Fundaciones"

    # Esperar que el frame haya cargado el detalle de la etapa
    expect(page).to have_text("Fundaciones", wait: 5)

    # El form de gasto está dentro del frame cargado — abrir el disclosure
    find("summary", text: /Nuevo gasto/i).click

    fill_in "Monto (centavos)", with: "15000"
    select "Mano de obra", from: "Categoría"
    fill_in "Descripción", with: "Jornal del lunes"
    click_button "Registrar gasto"

    expect(page).to have_text("Gasto registrado correctamente")
    expect(page).to have_text("Jornal del lunes")
  end
end
