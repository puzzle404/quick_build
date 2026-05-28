# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding a project-level expense (no stage)", type: :system, js: true do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }

  before { sign_in_user(owner) }

  it "owner opens the header modal and registers an expense without a stage" do
    visit constructors_project_path(project)

    # Regression guard: the form must not be reachable until the button opens it.
    expect(page).not_to have_field("Monto (centavos)")

    click_button "Registrar gasto"

    fill_in "Monto (centavos)", with: "250000"
    select "Mano de obra", from: "Categoría"
    fill_in "Descripción", with: "Compra de herramientas"

    click_button "Guardar gasto"

    expect(page).to have_text("Gasto registrado correctamente")

    expense = Expense.last
    expect(expense.project).to eq(project)
    expect(expense.project_stage).to be_nil
    expect(expense.amount_cents).to eq(250_000)
    expect(expense.author).to eq(owner)
  end
end
