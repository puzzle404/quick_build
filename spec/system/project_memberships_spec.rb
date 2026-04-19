require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  let(:constructor) { create(:user, :constructor) }
  let!(:member) { create(:user) }
  let!(:project) { create(:project, owner: constructor) }

  # NOTE: the inline "add member" form on the project show page was removed
  # in the Quick Build OS redesign. Membership management now lives under the
  # team panel via /constructors/projects/:id/project_memberships. Marking as
  # pending until we rewire the system spec to the new entry point.
  it 'constructor adds and views members', skip: 'Relocated by redesign — needs rewrite against /project_memberships' do
    sign_in_user(constructor)
    visit constructors_project_path(project)
    select member.email, from: 'Selecciona un usuario'
    select 'Editor', from: 'Rol en el proyecto'
    click_button 'Agregar miembro'

    expect(page).to have_text(member.email)
    expect(page).to have_text('Editor')
  end
end
