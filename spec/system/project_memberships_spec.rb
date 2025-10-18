require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  let(:constructor) { create(:user, :constructor) }
  let!(:member) { create(:user) }
  let!(:project) { create(:project, owner: constructor) }

  before do
    driven_by(:rack_test)
  end

  it 'constructor adds and views members' do
    sign_in_user(constructor)
    visit constructors_project_path(project)

    select member.email, from: 'project_membership_user_id'
    select 'Editor', from: 'project_membership_role'
    click_button 'Agregar miembro'

    expect(page).to have_text(member.email)
    expect(page).to have_text('Editor')
  end
end
