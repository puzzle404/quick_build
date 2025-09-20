class Constructors::ProjectsController < Constructors::BaseController
  before_action :authenticate_user!
  before_action :set_project, only: :show


  def show
    authorize @project
  end

  def index
    @projects = current_user.owned_projects
  end

  def new
    @project = current_user.owned_projects.build
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    if @project.save
      redirect_to constructors_project_path(@project), notice: 'Project created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def project_params
    params.require(:project)
          .permit(:name, :location, :start_date, :end_date, :status, :latitude, :longitude, images: [])
  end

  def set_project
    @project = current_user.owned_projects.find(params[:id])
  end
end