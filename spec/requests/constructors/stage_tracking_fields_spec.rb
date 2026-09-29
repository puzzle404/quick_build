require 'rails_helper'

# El form de etapa no permitía editar progress / lead / budget_cents, que son
# justamente los tres campos que el resto de la app muestra (card, drawer,
# Gantt, CSV, curva S). Este spec cubre el round-trip completo.
RSpec.describe 'Constructors::Projects::Stages tracking fields', type: :request do
  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage)   { create(:project_stage, project: project, name: 'Fundaciones') }

  before { sign_in(owner) }

  it 'expone avance, responsable y presupuesto en el form de edición' do
    get edit_constructors_project_stage_path(project, stage)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('project_stage[progress]')
    expect(response.body).to include('project_stage[lead]')
    expect(response.body).to include('project_stage[budget_pesos]')
    expect(response.body).to include('Seguimiento')
  end

  it 'no muestra el bloque Seguimiento al crear (avance y gastado son 0)' do
    get new_constructors_project_stage_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('project_stage[progress]')
  end

  it 'guarda avance, responsable y presupuesto tipeado en pesos es-AR' do
    patch constructors_project_stage_path(project, stage),
          params: { project_stage: { name: 'Fundaciones', progress: '42',
                                     lead: 'Juan Pérez', budget_pesos: '1.500.000,50' } }

    stage.reload
    expect(stage.progress).to eq(42)
    expect(stage.lead).to eq('Juan Pérez')
    expect(stage.budget_cents).to eq(150_000_050)
  end
end
