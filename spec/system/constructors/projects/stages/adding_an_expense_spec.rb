# frozen_string_literal: true

require "rails_helper"

# JS (Cuprite): the Gastos tab + the "Nuevo gasto" modal both require Stimulus.
RSpec.describe "Adding an expense to a stage", type: :system, js: true do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }
  let(:stage) { create(:project_stage, project: project, name: "Etapa Principal") }

  before { sign_in_user(owner) }

  it "owner adds an expense via the Gastos tab modal" do
    visit constructors_project_stage_path(project, stage)

    find(".tab", text: /Gastos/).click
    click_button("Nuevo gasto")

    fill_in "Monto (centavos)", with: "250000"
    select "Mano de obra", from: "Categoría"
    fill_in "Descripción", with: "Pago de jornales semana 1"
    click_button "Guardar gasto"

    # After submit the frame reloads and the Gastos tab count becomes 1 — a
    # visible, reliable sync point (the new expense sits in the now-inactive panel).
    expect(page).to have_css(".tab .count", text: "1", wait: 5)
    expense = stage.expenses.reload.last
    expect(expense).to be_present
    expect(expense.amount_cents).to eq(250_000)
    expect(expense.description).to eq("Pago de jornales semana 1")
    expect(expense.category).to eq("labor")
  end
end
