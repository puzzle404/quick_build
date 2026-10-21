require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  let(:constructor) { create(:user, :constructor) }
  let!(:member) { create(:user) }
  let!(:project) { create(:project, owner: constructor) }

  # Invitar miembro vive en la tab Equipo del proyecto (MembersPanelComponent →
  # InviteMemberDrawerComponent), un qb--drawer self-contained abierto por
  # "Invitar"; el rail de la vista de proyecto ya no repite el equipo. The dialog renders in the DOM but starts
  # closed (no .qb-drawer-open class) — qb--drawer#open toggles it on click.
  # In rack_test (no JS/CSS) we can submit the form by passing visible: :all
  # (or :hidden) when finding inputs.
  it 'constructor adds and views members' do
    sign_in_user(constructor)
    visit constructors_project_people_path(project)

    Capybara.using_wait_time(2) do
      # select_option y no .set: en rack_test .set no elige opciones de un <select>.
      page.find_by_id('project_membership_user_id', visible: :all)
          .find("option[value='#{member.id}']", visible: :all).select_option
      page.find_by_id('project_membership_role', visible: :all)
          .find("option[value='editor']", visible: :all).select_option
      page.find_button('Agregar miembro', visible: :all).click
    end

    expect(page).to have_text(member.email)
  end
end
