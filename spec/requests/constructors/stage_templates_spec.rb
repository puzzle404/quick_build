# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::StageTemplates", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:other) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, start_date: Date.new(2026, 3, 1)) }

  describe "POST /constructors/stage_templates" do
    before { sign_in(owner) }

    it "guarda las etapas de la obra como plantilla" do
      create(:project_stage, project: project, name: "Estructura")

      expect {
        post constructors_stage_templates_path,
             params: { stage_template: { project_id: project.id, name: "Obra tipo" } }
      }.to change(StageTemplate, :count).by(1)

      expect(response).to redirect_to(constructors_project_path(project))
      expect(StageTemplate.last.items.pluck(:name)).to eq([ "Estructura" ])
    end

    it "avisa cuando la obra no tiene etapas" do
      expect {
        post constructors_stage_templates_path,
             params: { stage_template: { project_id: project.id, name: "Vacía" } }
      }.not_to change(StageTemplate, :count)

      expect(flash[:alert]).to include("no tiene etapas")
    end

    it "no permite guardar una plantilla desde la obra de otro" do
      foreign = create(:project, owner: other)

      expect {
        post constructors_stage_templates_path,
             params: { stage_template: { project_id: foreign.id, name: "Ajena" } }
      }.not_to change(StageTemplate, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /constructors/stage_templates" do
    it "lista sólo las plantillas propias" do
      mine = create(:stage_template, owner: owner, name: "Mía")
      theirs = create(:stage_template, owner: other, name: "Ajena")

      sign_in(owner)
      get constructors_stage_templates_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(theirs.name)
    end
  end

  describe "DELETE /constructors/stage_templates/:id" do
    it "borra la plantilla propia" do
      template = create(:stage_template, owner: owner)
      sign_in(owner)

      expect { delete constructors_stage_template_path(template) }
        .to change(StageTemplate, :count).by(-1)
    end

    it "no borra la plantilla de otro" do
      template = create(:stage_template, owner: other)
      sign_in(owner)

      expect { delete constructors_stage_template_path(template) }
        .not_to change(StageTemplate, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST apply_template con stage_template_id" do
    before { sign_in(owner) }

    it "aplica una plantilla propia" do
      template = create(:stage_template, owner: owner)
      create(:stage_template_item, stage_template: template, name: "Movimiento de suelos")

      post apply_template_constructors_project_stages_path(project),
           params: { stage_template_id: template.id }

      expect(project.project_stages.pluck(:name)).to eq([ "Movimiento de suelos" ])
    end

    it "rechaza la plantilla de otro constructor sin crear etapas" do
      foreign = create(:stage_template, owner: other)
      create(:stage_template_item, stage_template: foreign, name: "Rubro secreto")

      expect {
        post apply_template_constructors_project_stages_path(project),
             params: { stage_template_id: foreign.id }
      }.not_to change(ProjectStage, :count)

      expect(flash[:alert]).to eq("No encontramos esa plantilla.")
    end

    it "sin id sigue aplicando la plantilla base" do
      post apply_template_constructors_project_stages_path(project)

      expect(project.project_stages.root.count).to eq(3)
    end
  end
end
