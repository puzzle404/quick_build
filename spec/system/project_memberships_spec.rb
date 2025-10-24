require 'rails_helper'

RSpec.describe 'Project membership management', type: :system do
  let(:constructor) { create(:user, :constructor) }
  let!(:member) { create(:user) }
  let!(:project) { create(:project, owner: constructor) }

  it 'constructor adds and views members' do
    sign_in_user(constructor)
    visit constructors_project_path(project)
    select member.email, from: 'Selecciona un usuario'
    select 'Editor', from: 'Rol en el proyecto'
    click_button 'Agregar miembro'

    expect(page).to have_text(member.email)
    expect(page).to have_text('Editor')
  end
end
