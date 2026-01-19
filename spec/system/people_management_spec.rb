require 'rails_helper'

RSpec.describe 'People management', type: :system do
  let(:owner) { create(:user, :constructor, email: 'constructor@example.com') }
  let(:project) { create(:project, owner: owner, name: 'Obra A') }

  it 'creates a person and registers attendance' do
    sign_in_user(owner)

    visit constructors_project_people_path(project)
    click_link 'Nueva persona'

    fill_in 'Nombre y apellido', with: 'Carlos Gómez'
    fill_in 'Rol / oficio', with: 'Herrero'
    click_button 'Crear persona'

    expect(page).to have_text('Carlos Gómez')
    expect(page).to have_text('Herrero')

    # Register attendance
    click_button 'Dar presente'
    expect(page).to have_text('Presente registrado').or have_text('Asistencias')
  end
end
