require 'rails_helper'

RSpec.describe "Project management", type: :system do
  let(:constructor) { create(:user, :constructor) }

  it "allows a constructor to create a project" do
    sign_in constructor
    visit projects_path
    click_link "New Project"
    fill_in "Name", with: "My Project"
    fill_in "Location", with: "Town"
    fill_in "Start date", with: Date.today
    fill_in "End date", with: Date.today + 1
    click_button "Save"
    expect(page).to have_content("My Project")
  end
end
