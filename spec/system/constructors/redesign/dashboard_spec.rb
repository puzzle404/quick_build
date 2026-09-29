require 'rails_helper'

RSpec.describe 'QB OS · Dashboard', type: :system do
  let(:user) { create(:user, :constructor) }
  before do
    create(:project, owner: user, status: :in_progress, name: 'Aurora')
    create(:project, owner: user, status: :planned,     name: 'Pilar')
    create(:project, owner: user, status: :completed,   name: 'Retiro')
    sign_in_user(user)
  end

  it 'renders greeting + hero strip with status counts' do
    visit constructors_root_path
    expect(page).to have_text(/Buen[oa]s\s+(días|tardes|noches)/i)
    expect(page).to have_text('Obras totales')
    expect(page).to have_text('En progreso')
    expect(page).to have_text('Planificadas')
    expect(page).to have_text('Completadas')
  end

  it 'renders the Active projects table' do
    visit constructors_root_path
    expect(page).to have_text('Obras activas')
    # Active projects are non-completed; Aurora and Pilar should appear, Retiro should not.
    expect(page).to have_text('Aurora')
    expect(page).to have_text('Pilar')
  end

  it 'renders the right column panels' do
    visit constructors_root_path
    expect(page).to have_text('Alertas · hoy')
    expect(page).to have_text('Actividad reciente')
    expect(page).to have_text('Próximas etapas · 14 días')
  end
end
