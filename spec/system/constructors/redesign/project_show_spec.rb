require 'rails_helper'

RSpec.describe 'QB OS · Project show + Overview', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora', client: 'Delta', status: :in_progress) }
  before { sign_in_user(user) }

  it 'renders the project header with code + status pill + metric strip' do
    visit constructors_project_path(project)
    expect(page).to have_text(/PRJ-\d+/)
    expect(page).to have_text('En progreso')
    expect(page).to have_text('Aurora')
    expect(page).to have_text('Avance físico')
    expect(page).to have_text('Gastos a la fecha')
    expect(page).to have_text('Etapas')
    expect(page).to have_text('Días a entrega')
  end

  it 'renders the 5 inner tabs (Resumen + Planificación unificados en Etapas)' do
    visit constructors_project_path(project)
    %w[Etapas Materiales Equipo Documentos].each do |label|
      expect(page).to have_text(label)
    end
    expect(page).to have_text('Planos')
    # "Planificación" ya no es una pestaña propia — pero SÍ sigue siendo el
    # eyebrow legítimo de los drawers de plantillas/nueva etapa (click-driven
    # qb--drawer, cerrados por default pero presentes en el DOM bajo
    # rack_test), así que el check se acota a la barra de tabs, no a la
    # página entera.
    within('.qb-tabs-row') { expect(page).to have_no_text('Planificación') }
  end

  it 'renders the stages workspace (switcher + actions) on the landing page' do
    visit constructors_project_path(project)
    expect(page).to have_button('Gantt')
    expect(page).to have_no_button('WBS')
    expect(page).to have_link('Nueva etapa', href: new_constructors_project_stage_path(project))
    expect(page).to have_button('Aplicar plantilla')
  end

  # Panel de la obra: 3 tarjetas siempre a la vista, sin tabs. La bitácora
  # tiene su propia tab de sección.
  it 'renders the project panel: avance, atención y datos de la obra' do
    visit constructors_project_path(project)
    within('.qb-project-rail') do
      expect(page).to have_no_css('.qb-tab')
      expect(page).to have_text('Avance de obra')
      expect(page).to have_text('Requiere atención')
      expect(page).to have_text('Plazo')
      expect(page).to have_text('Presupuesto')
      expect(page).to have_no_text('Bitácora')
    end
    within('.qb-tabs-row') { expect(page).to have_link('Bitácora') }
  end
end
