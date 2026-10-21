require 'rails_helper'

RSpec.describe 'QB OS · Team', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before do
    create(:project_person, project: project, full_name: 'Pedro García', status: :active)
    create(:project_person, project: project, full_name: 'Ana Ruiz', status: :inactive)
    sign_in_user(user)
  end

  it 'renders KPI strip with attendance metric' do
    visit constructors_project_people_path(project)
    expect(page).to have_text('Personas asignadas')
    expect(page).to have_text('En licencia')
    expect(page).to have_text('Asistencia promedio')
    expect(page).to have_text('Costo MO')
  end

  it 'lists people in the table' do
    visit constructors_project_people_path(project)
    expect(page).to have_text('Pedro García')
    expect(page).to have_text('Ana Ruiz')
  end

  it 'shows status pills (Activa / Licencia)' do
    visit constructors_project_people_path(project)
    expect(page).to have_text('Activa')
    expect(page).to have_text('Licencia')
  end

  it 'shows the Invitar persona action' do
    visit constructors_project_people_path(project)
    expect(page).to have_link('Invitar persona')
  end
end
