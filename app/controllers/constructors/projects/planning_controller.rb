module Constructors
  module Projects
    class PlanningController < Constructors::BaseController
      before_action :set_project

      def show
        authorize @project, :show?
        @project_stages = @project.project_stages.includes(:material_lists).ordered
        @new_stage = @project.project_stages.build
        @project = @project.decorate
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end
    end
  end
end
