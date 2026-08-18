# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Projects::Stages drawer", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  before { sign_in(constructor) }

  it "renders the drawer panel for a turbo-frame request to #new" do
    get new_constructors_project_stage_path(project), headers: { "Turbo-Frame" => "drawer" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="drawer"')
    expect(response.body).to include("qb-drawer-panel")
  end

  it "renders the full-page fallback for a normal request to #new" do
    get new_constructors_project_stage_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nueva etapa")
    # Sin esto el ejemplo pasaba con CUALQUIERA de las dos ramas: el título
    # aparece en las dos. La ausencia del panel del drawer es lo que prueba
    # que se sirvió la página completa.
    expect(response.body).not_to include("qb-drawer-panel")
  end

  it "closes the drawer and appends the new stage card on create" do
    post constructors_project_stages_path(project),
         params: { project_stage: { name: "Fundaciones" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('turbo-stream action="update" target="drawer"')
    expect(response.body).to include('turbo-stream action="append" target="planning_stages"')
  end

  # StageDetailComponent ya no renderiza su propio <h1>: el título vive en el
  # header de Qb::DrawerComponent, provisto por stages/show.html.erb vía
  # content_for(:drawer). Este es el call site que prueba ese título.
  it "renders the drawer panel with the stage title for a turbo-frame request to #show" do
    stage = create(:project_stage, project: project, name: "Fundaciones")

    get constructors_project_stage_path(project, stage), headers: { "Turbo-Frame" => "drawer" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="drawer"')
    expect(response.body).to include("qb-drawer-title")
    expect(response.body).to include("Fundaciones")
  end

  it "renders the full-page fallback for a normal request to #show" do
    stage = create(:project_stage, project: project, name: "Fundaciones")

    get constructors_project_stage_path(project, stage)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fundaciones")
    # Idem #new: el nombre de la etapa sale en las dos ramas, así que lo que
    # distingue la página completa del drawer es que no haya panel.
    expect(response.body).not_to include("qb-drawer-panel")
  end
end
