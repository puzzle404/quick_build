require 'rails_helper'

# hourly_rate_cents existía en la tabla desde siempre pero no había forma de
# cargarlo (0 de 49 registros lo tenían): no estaba en person_params ni en el
# form. Los KPI "Tarifa" de las dos fichas eran guion permanente.
RSpec.describe 'Constructors::Projects::People hourly rate', type: :request do
  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:person)  { create(:project_person, project: project, full_name: 'Carla Ruiz') }

  before { sign_in(owner) }

  it 'guarda la tarifa tipeada en pesos es-AR' do
    patch constructors_project_person_path(project, person),
          params: { project_person: { full_name: person.full_name, hourly_rate_pesos: '8.500,75' } }

    expect(person.reload.hourly_rate_cents).to eq(850_075)
  end

  it 'permite volver a dejarla vacía' do
    person.update!(hourly_rate_cents: 500_000)

    patch constructors_project_person_path(project, person),
          params: { project_person: { full_name: person.full_name, hourly_rate_pesos: '' } }

    expect(person.reload.hourly_rate_cents).to be_nil
  end

  it 'la ficha muestra la tarifa y ya no el KPI de horas' do
    person.update!(hourly_rate_cents: 850_000)
    get constructors_project_person_path(project, person)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Días trabajados')
    expect(response.body).not_to include('Horas registradas')
  end
end
