module Constructors
  module Projects
    # La vista de planificación ahora vive en stages#index.
    # Este controlador existe solo para 301-redirigir bookmarks antiguos.
    class PlanningController < Constructors::BaseController
      before_action :set_project

      def show
        redirect_to constructors_project_stages_path(@project), status: :moved_permanently
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end
    end
  end
end
