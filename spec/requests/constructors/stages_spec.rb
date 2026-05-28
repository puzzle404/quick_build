# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Projects::Stages", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:other) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  describe "POST /constructors/projects/:project_id/stages/:id/duplicate" do
    context "as project owner" do
      before { sign_in(owner) }

      context "when stage has no sub-stages" do
        let!(:stage) do
          create(:project_stage, project: project, name: "Estructura", progress: 60,
                 budget_cents: 500_000)
        end

        it "creates exactly one new stage and redirects to planning" do
          expect {
            post duplicate_constructors_project_stage_path(project, stage)
          }.to change(ProjectStage, :count).by(1)

          # La copia aparece en la lista de etapas (no navegamos a su detalle).
          expect(response).to redirect_to(constructors_project_stages_path(project))
        end

        it "sets the new stage name with '(copia)' suffix" do
          post duplicate_constructors_project_stage_path(project, stage)
          expect(ProjectStage.last.name).to eq("Estructura (copia)")
        end

        it "resets progress to 0" do
          post duplicate_constructors_project_stage_path(project, stage)
          expect(ProjectStage.last.progress).to eq(0)
        end

        it "copies budget_cents from original" do
          post duplicate_constructors_project_stage_path(project, stage)
          expect(ProjectStage.last.budget_cents).to eq(500_000)
        end
      end

      context "when stage has sub-stages" do
        let!(:stage) { create(:project_stage, project: project, name: "Mampostería") }
        let!(:sub1) { create(:project_stage, project: project, parent_id: stage.id, name: "Sub A", progress: 100) }
        let!(:sub2) { create(:project_stage, project: project, parent_id: stage.id, name: "Sub B", progress: 50) }

        it "creates stage + all sub-stages (count +3)" do
          expect {
            post duplicate_constructors_project_stage_path(project, stage)
          }.to change(ProjectStage, :count).by(3)
        end

        it "all duplicated sub-stages have progress 0" do
          post duplicate_constructors_project_stage_path(project, stage)
          new_stage = ProjectStage.where(name: "Mampostería (copia)").last
          expect(new_stage).to be_present
          new_stage.sub_stages.each do |sub|
            expect(sub.progress).to eq(0)
          end
        end

        it "new sub-stages are children of the duplicated root stage" do
          post duplicate_constructors_project_stage_path(project, stage)
          new_stage = ProjectStage.where(name: "Mampostería (copia)").last
          expect(new_stage.sub_stages.count).to eq(2)
        end
      end
    end

    context "as non-owner" do
      before { sign_in(other) }

      let!(:stage) { create(:project_stage, project: project, name: "Pintura") }

      it "is blocked and does not create a stage" do
        expect {
          post duplicate_constructors_project_stage_path(project, stage)
        }.not_to change(ProjectStage, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /constructors/projects/:project_id/stages/:id/complete" do
    context "as project owner" do
      before { sign_in(owner) }

      let!(:stage) { create(:project_stage, project: project, name: "Cimientos", progress: 40) }

      it "sets progress to 100 and redirects with notice" do
        patch complete_constructors_project_stage_path(project, stage)

        stage.reload
        expect(stage.progress).to eq(100)
        expect(response).to redirect_to(constructors_project_stage_path(project, stage))
      end
    end

    context "as non-owner" do
      before { sign_in(other) }

      let!(:stage) { create(:project_stage, project: project, name: "Instalaciones", progress: 30) }

      it "is blocked and does not update progress" do
        patch complete_constructors_project_stage_path(project, stage)

        stage.reload
        expect(stage.progress).to eq(30)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
