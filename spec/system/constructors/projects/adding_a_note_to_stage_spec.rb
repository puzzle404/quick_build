# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding a note to a stage", type: :system do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }
  let(:stage) { create(:project_stage, project: project, name: "Etapa Principal") }

  before { sign_in_user(owner) }

  it "owner can add a note via the Notas tab modal and see it in the list" do
    visit constructors_project_stage_path(project, stage)

    # Click the "Notas" tab in the tabbed panel
    find(".tab", text: /Notas/).click

    # Click the "Nueva nota" button to open the modal
    find("button", text: /Nueva nota/i).click

    fill_in "Nota", with: "Verificar instalación de cañerías"

    click_button "Guardar"

    expect(page).to have_text("Nota agregada correctamente")
    expect(page).to have_text("Verificar instalación de cañerías")
  end
end
