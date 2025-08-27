require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'constructor adds and views members' do
    constructor = create(:user, :constructor)
    member = create(:user)
    project = create(:project, owner: constructor)

    sign_in constructor
    visit project_path(project)

    select member.email, from: 'project_membership_user_id'
    fill_in 'project_membership_role', with: 'worker'
    click_button 'Add Member'

    expect(page).to have_css('#members', text: member.email)
  end
end
