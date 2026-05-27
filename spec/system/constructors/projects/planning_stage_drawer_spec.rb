# frozen_string_literal: true

require "rails_helper"

# JS (Cuprite): the drawer (qb--drawer), the work-area tabs (qb--tabs) and the
# expense modal (qb--modal) all require Stimulus + Turbo Frame.
RSpec.describe "Planning stage drawer", type: :system, js: true do
  it "opens the stage detail in the drawer and registers an expense" do
    owner   = create(:user, :constructor)
    project = create(:project, owner: owner)
    stage   = create(:project_stage, project: project, name: "Fundaciones",
                                     start_date: Date.current, end_date: Date.current + 10)

    sign_in_user(owner)
    visit constructors_project_planning_path(project)

    # Click the stage: loads the detail into the stage_detail frame + opens the drawer.
    click_on "Fundaciones"
    expect(page).to have_text("Fundaciones", wait: 5)

    find(".qb-tab", text: /Gastos/).click
    click_button("Nuevo gasto")

    fill_in "Monto (centavos)", with: "15000"
    select "Mano de obra", from: "Categoría"
    fill_in "Descripción", with: "Jornal del lunes"
    click_button "Guardar gasto"

    # After submit the frame reloads and the Gastos tab count becomes 1 (sync point).
    expect(page).to have_css(".qb-tab-count", text: "1", wait: 5)
    expect(stage.expenses.reload.last&.description).to eq("Jornal del lunes")
  end
end
