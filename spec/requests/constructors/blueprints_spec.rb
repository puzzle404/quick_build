require 'rails_helper'

RSpec.describe 'Constructors::Blueprints', type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before { sign_in(owner) }

  it 'monta el visor real (canvas + values del controller) en el índice' do
    blueprint = create(:blueprint, :with_scale, project: project, name: 'Planta baja')

    get constructors_project_blueprints_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="blueprint-viewer"')
    expect(response.body).to include('data-blueprint-viewer-target="canvas"')
    expect(response.body).to include("data-blueprint-viewer-blueprint-id-value=\"#{blueprint.id}\"")
    expect(response.body).to include('data-blueprint-viewer-construction-items-value')
    # El botón de subir vive sólo en el header strip
    expect(response.body.scan('Subir plano').size).to eq(1)
    expect(response.body).not_to include('Abrir viewer')
  end

  it '?selected= elige qué plano abre el visor' do
    create(:blueprint, project: project, name: 'Primero')
    other = create(:blueprint, project: project, name: 'Segundo')

    get constructors_project_blueprints_path(project, selected: other.id)

    expect(response.body).to include("data-blueprint-viewer-blueprint-id-value=\"#{other.id}\"")
  end

  it 'blueprints#show en desktop redirige a la vista única' do
    blueprint = create(:blueprint, project: project)

    get constructors_project_blueprint_path(project, blueprint)

    expect(response).to redirect_to(constructors_project_blueprints_path(project, selected: blueprint.id))
  end
end
