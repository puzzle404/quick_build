require 'rails_helper'

RSpec.describe 'QB OS · Materials', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before do
    create(:material_list, project: project, author: user, name: 'Hierros estructura', status: :approved)
    create(:material_list, project: project, author: user, name: 'Cemento revoques', status: :draft)
    sign_in_user(user)
  end

  it 'renders the KPI strip with status counts' do
    visit constructors_project_material_lists_path(project)
    expect(page).to have_text('Listas totales')
    expect(page).to have_text('Valor acumulado')
    expect(page).to have_text('Aprobadas')
    expect(page).to have_text('En revisión')
    expect(page).to have_text('Borradores')
  end

  it 'renders the search + 3 filter chips' do
    visit constructors_project_material_lists_path(project)
    expect(page).to have_field('q')
    expect(page).to have_text('Estado:')
    expect(page).to have_text('Etapa:')
    expect(page).to have_text('Origen:')
  end

  it 'lists material list cards' do
    visit constructors_project_material_lists_path(project)
    expect(page).to have_text('Hierros estructura')
    expect(page).to have_text('Cemento revoques')
  end

  it 'filters by ?status=approved' do
    visit constructors_project_material_lists_path(project, status: 'approved')
    expect(page).to have_text('Hierros estructura')
    expect(page).not_to have_text('Cemento revoques')
  end
end
