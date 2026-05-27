require 'rails_helper'

RSpec.describe 'QB OS · Project show + Overview', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora', client: 'Delta', status: :in_progress) }
  before { sign_in_user(user) }

  it 'renders the project header with code + status pill + metric strip' do
    visit constructors_project_path(project)
    expect(page).to have_text(/PRJ-\d+/)
    expect(page).to have_text('En obra')
    expect(page).to have_text('Aurora')
    expect(page).to have_text('Avance físico')
    expect(page).to have_text('Gastos a la fecha')
    expect(page).to have_text('Etapas')
    expect(page).to have_text('Días a entrega')
  end

  it 'renders all 6 inner tabs' do
    visit constructors_project_path(project)
    %w[Resumen Planificación Materiales Equipo Documentos].each do |label|
      expect(page).to have_text(label)
    end
    expect(page).to have_text('Planos · IA')
  end

  it 'renders Overview sections (S-curve, mini-map, risks, team)' do
    visit constructors_project_path(project)
    expect(page).to have_text('Curva S · Real vs Plan')
    expect(page).to have_text('Mini-map de obra')
    expect(page).to have_text('Riesgos y bloqueos')
    expect(page).to have_text('Ubicación')
    expect(page).to have_text('Equipo asignado')
    expect(page).to have_text('Documentos recientes')
  end
end
