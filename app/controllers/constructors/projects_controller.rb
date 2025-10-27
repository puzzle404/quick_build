class Constructors::ProjectsController < Constructors::BaseController
  before_action :set_project, only: %i[show edit update]
  before_action :set_activity_entries, only: :show

  def show
    authorize @project
    @project = @project.decorate
    @members = @project.members.order(created_at: :desc)
    @membership = @project.project_memberships.build
  end

  def index
    @projects = current_user.owned_projects.order(updated_at: :desc)
  end

  def new
    @project = current_user.owned_projects.build
    authorize @project
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    authorize @project

    if @project.save
      redirect_to constructors_project_path(@project), notice: "Obra creada correctamente."
    else
      flash.now[:alert] = "Revisa los datos y vuelve a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project
    @project_summary = @project.decorate
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente."
    else
      @project_summary = @project.decorate
      flash.now[:alert] = "No pudimos guardar los cambios. Revisa los datos e inténtalo otra vez."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def project_params
    params.require(:project)
          .permit(:name, :location, :start_date, :end_date, :status, :latitude, :longitude, images: [], documents: [])
  end

  def set_project
    @project = current_user.owned_projects.find(params[:id])
  end

  def set_activity_entries
    @activity_entries ||= Projects::ActivitiesService.perform(@project)
  end
end
