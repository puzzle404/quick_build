require 'rails_helper'

RSpec.describe "Project management", type: :system do
  let(:constructor) { create(:user, :constructor) }

  it "allows a constructor to create a project" do
    sign_in_user(constructor)
    visit new_constructors_project_path
    fill_in "Name", with: "My Project"
    fill_in "Location", with: "Town"
    fill_in "Start date", with: Date.today
    fill_in "End date", with: Date.today + 1
    click_button "Crear obra"
    expect(page).to have_content("My Project")
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
