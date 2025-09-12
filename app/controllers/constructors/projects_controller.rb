class Constructors::ProjectsController < Constructors::BaseController
  before_action :authenticate_user!
  before_action :require_constructor!
  before_action :set_project, only: :show

  def index
    @projects = current_user.owned_projects
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    respond_to do |format|
      if @project.save
        format.html { redirect_to projects_path, notice: 'Project created successfully.' }
      else
        format.html { redirect_to new_project_path, alert: 'Error creating project.' }
      end
    end
  end

  def show
    authorize @project
  end

  private

  def require_constructor!
    redirect_to root_path, alert: 'Not authorized' unless current_user.constructor?
  end

  def project_params
    params.require(:project).permit(:name, :location, :start_date, :end_date, :status, :owner_id)
  end

  def set_project
    @project = Project.find(params[:id])
  end
end