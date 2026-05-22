module Constructors
  module Projects
    class PlanningController < Constructors::BaseController
      before_action :set_project

      def show
        authorize @project, :show?
        @current_qb_section = :projects
        @project = @project.decorate
        @current_qb_project = @project
        @current_qb_project_sub = :planning
        @root_stages = @project.project_stages.where(parent_id: nil).order(:position).includes(:sub_stages)
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end
    end
  end
end
