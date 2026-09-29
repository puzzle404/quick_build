module Constructors
  module Projects
    # La vista de planificación ahora vive en stages#index.
    # Este controlador existe solo para 301-redirigir bookmarks antiguos.
    class PlanningController < Constructors::BaseController
      before_action :find_project!

      def show
        authorize @project, :show?
        redirect_to constructors_project_stages_path(@project), status: :moved_permanently
      end
    end
  end
end
