# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding a note to a project", type: :system do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }

  before { sign_in_user(owner) }

  it "owner can add a note and see it in the list" do
    visit constructors_project_path(project)

    # Open the note form disclosure
    find("summary", text: "Nueva nota").click

    fill_in "Nota", with: "Coordinar con el arquitecto la semana próxima"

    click_button "Agregar nota"

    expect(page).to have_text("Nota agregada correctamente")
    expect(page).to have_text("Coordinar con el arquitecto la semana próxima")
  end
end
