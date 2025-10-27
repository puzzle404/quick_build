class Constructors::Projects::DocumentsController < Constructors::BaseController
  before_action :set_project

  def show
    authorize @project
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end
end

