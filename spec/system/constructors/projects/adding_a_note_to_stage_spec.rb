# frozen_string_literal: true

require "rails_helper"

# JS (Cuprite): the Notas tab + the "Nueva nota" modal both require Stimulus.
RSpec.describe "Adding a note to a stage", type: :system, js: true do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }
  let(:stage) { create(:project_stage, project: project, name: "Etapa Principal") }

  before { sign_in_user(owner) }

  it "owner adds a note via the Notas tab modal" do
    visit constructors_project_stage_path(project, stage)

    find(".qb-tab", text: /Notas/).click
    click_button("Nueva nota")

    fill_in "Nota", with: "Verificar instalación de cañerías"
    click_button "Guardar"

    # After submit the frame reloads and the Notas tab count becomes 1 (sync point).
    expect(page).to have_css(".qb-tab-count", text: "1", wait: 5)
    note = stage.notes.reload.last
    expect(note).to be_present
    expect(note.body).to eq("Verificar instalación de cañerías")
    expect(note.author).to eq(owner)
  end
end
