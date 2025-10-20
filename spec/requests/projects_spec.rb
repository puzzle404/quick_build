require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:constructor) { create(:user, :constructor) }

  before do
    sign_in constructor
  end

  describe "POST /projects" do
    it "creates a project" do
      project_params = {
        name: "Test",
        location: "City",
        start_date: Date.today,
        end_date: Date.today + 1,
        status: "planned"
      }
      expect {
        post constructors_projects_path, params: { project: project_params }
      }.to change(Project, :count).by(1)
      expect(response).to redirect_to(constructors_project_path(Project.last))
    end
  end

  describe "PATCH /projects/:id" do
    it "updates a project" do
      project = create(:project, owner: constructor, name: "Obra Sur", status: :planned)
      params = {
        name: "Obra Sur Actualizada",
        status: "in_progress"
      }

      patch constructors_project_path(project), params: { project: params }

      expect(response).to redirect_to(constructors_project_path(project))
      expect(project.reload).to have_attributes(
        name: "Obra Sur Actualizada",
        status: "in_progress"
      )
    end
  end
end
