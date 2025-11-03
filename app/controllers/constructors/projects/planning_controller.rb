module Constructors
  module Projects
    class PlanningController < Constructors::BaseController
      before_action :set_project

      def show
        authorize @project, :show?
        redirect_to constructors_project_stages_path(@project)
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end
    end
  end
end
