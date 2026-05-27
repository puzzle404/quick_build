# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding an expense to a stage", type: :system do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }
  let(:stage) { create(:project_stage, project: project, name: "Etapa Principal") }

  before { sign_in_user(owner) }

  it "owner can add an expense via the Gastos tab modal and see it in the list" do
    visit constructors_project_stage_path(project, stage)

    # Click the "Gastos" tab in the tabbed panel
    find(".tab", text: /Gastos/).click

    # Click the "Nuevo gasto" button to open the modal
    find("button", text: /Nuevo gasto/i).click

    # Fill in the form fields inside the modal
    fill_in "Monto (centavos)", with: "250000"
    select "Mano de obra", from: "Categoría"
    fill_in "Descripción", with: "Pago de jornales semana 1"

    click_button "Guardar gasto"

    expect(page).to have_text("Gasto registrado correctamente")
    expect(page).to have_text("Pago de jornales semana 1")
    expect(page).to have_text("Mano de obra")
  end
end
