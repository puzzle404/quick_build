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
    expect(body_without_templates).to include("qb-drawer-panel")
  end

  it "renders the full-page fallback for a normal request to #new" do
    get new_constructors_project_stage_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nueva etapa")
    # Sin esto el ejemplo pasaba con CUALQUIERA de las dos ramas: el título
    # aparece en las dos. La ausencia del panel del drawer es lo que prueba
    # que se sirvió la página completa.
    expect(body_without_templates).not_to include("qb-drawer-panel")
  end

  # Refresh (no append): el drawer de alta es click-driven y no se cerraba
  # al vaciar el frame global, lo que terminaba en etapas duplicadas.
  it "refreshes the page with a flash on create so the drawer closes" do
    expect {
      post constructors_project_stages_path(project),
           params: { project_stage: { name: "Fundaciones" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    }.to change(project.project_stages, :count).by(1)

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('turbo-stream action="refresh"')
    expect(flash[:notice]).to eq("Etapa creada correctamente.")
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
    expect(body_without_templates).not_to include("qb-drawer-panel")
  end

  it "el layout trae el overlay de carga y el esqueleto del drawer" do
    get constructors_project_path(project)

    expect(response.body).to include('data-controller="qb--keyboard qb--tweaks qb--mobile-detect qb--drawer qb--loading"')
    expect(response.body).to include('class="qb-page-loader"')
    expect(response.body).to include('<template data-qb--drawer-target="skeleton">')
  end
end
