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
  end

  it "closes the drawer and appends the new stage card on create" do
    post constructors_project_stages_path(project),
         params: { project_stage: { name: "Fundaciones" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('turbo-stream action="update" target="drawer"')
    expect(response.body).to include('turbo-stream action="append" target="planning_stages"')
  end
end
