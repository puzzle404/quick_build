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

  # Rail: 2 tabs — Seguimiento (salud, curva, alertas, vencimientos,
  # bitácora) y Datos de la obra (la ficha cargada al crearla). Sin JS
  # (rack_test) los paneles salen todos visibles.
  it 'renders the project rail: Seguimiento / Datos de la obra tabs' do
    visit constructors_project_path(project)
    within('.qb-project-rail') do
      expect(page.all('.qb-tab').map { |t| t.text.squish }).to eq([ 'Seguimiento', 'Datos de la obra' ])
      expect(page).to have_text('Real vs plan')
      expect(page).to have_text('Curva S · real vs plan')
      expect(page).to have_text('Alertas')
      expect(page).to have_text('Próximos vencimientos')
      expect(page).to have_button('Guardar nota')
      expect(page).to have_text('Cargado al crear la obra')
      expect(page).to have_text('Cliente')
      expect(page).to have_text('Presupuesto')
      # Lo que ya vive en otra tab (equipo, documentos) no se repite en el rail.
      expect(page).to have_no_text('Documentos recientes')
      expect(page).to have_no_link('Ver equipo')
    end
  end
end
