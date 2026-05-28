# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding a note to a project", type: :system do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }

  before { sign_in_user(owner) }

  # El form de "Agregar nota" ahora vive en una modal (qb--modal) que se abre
  # con el botón "Agregar nota". Sin JS la modal no se abre pero su markup
  # queda en el DOM, así que el spec puede llenar y submitear el form
  # directamente bajo rack_test.
  it "owner can add a note and see it in the list" do
    visit constructors_project_path(project)

    fill_in "Nota", with: "Coordinar con el arquitecto la semana próxima"

    click_button "Guardar"

    expect(page).to have_text("Nota agregada correctamente")
    expect(page).to have_text("Coordinar con el arquitecto la semana próxima")
  end
end
