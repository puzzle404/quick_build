require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  let(:constructor) { create(:user, :constructor) }
  let!(:member) { create(:user) }
  let!(:project) { create(:project, owner: constructor) }

  # The redesign moved the inline form to a centered modal opened by the
  # "Invitar" button in the Equipo asignado section. The dialog renders in
  # the DOM but starts hidden via inline display:none — qb--modal#open
  # toggles it on click. In rack_test (no JS) we can submit the form by
  # passing visible: :all (or :hidden) when finding inputs.
  it 'constructor adds and views members' do
    sign_in_user(constructor)
    visit constructors_project_path(project)

    Capybara.using_wait_time(2) do
      page.find_by_id('project_membership_user_id', visible: :all).set(member.id)
      page.find_by_id('project_membership_role',    visible: :all).set('editor')
      page.find_button('Agregar miembro', visible: :all).click
    end

    expect(page).to have_text(member.email)
  end
end
