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
    @query = params[:q].to_s.strip
    @from_date = params[:from_date].presence
    @to_date = params[:to_date].presence

    @projects = Constructors::Projects::ProjectSearchService.new(
      scope: current_user.owned_projects,
      query: @query,
      from_date: @from_date,
      to_date: @to_date
    ).results
  end

  def new
    @project = current_user.owned_projects.build
    authorize @project
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    authorize @project

    if persist_project_with_documents(@project)
      flash[:new_project] = true
      redirect_to constructors_project_path(@project), notice: "¡Obra creada correctamente!"
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

    @project.assign_attributes(project_params)

    if persist_project_with_documents(@project)
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
          .permit(:name, :location, :start_date, :end_date, :status, :latitude, :longitude, document_files: [])
  end

  def set_project
    @project = current_user.owned_projects.find(params[:id])
  end

  def set_activity_entries
    @activity_entries ||= Projects::ActivitiesService.perform(@project)
  end

  def persist_project_with_documents(project)
    ActiveRecord::Base.transaction do
      project.save!
      attach_images_from_params!(project)
      attach_documents_from_params!(project)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    assign_errors_from_exception(project, e)
    false
  end

  def attach_documents_from_params!(project)
    files = Array.wrap(params.dig(:project, :document_files)).compact_blank
    return if files.empty?

    files.each do |uploaded_file|
      document = project.documents.build
      document.file.attach(uploaded_file)
      document.save!
    end
  end

  def attach_images_from_params!(project)
    images = Array.wrap(params.dig(:project, :images)).compact_blank
    return if images.empty?

    images.each do |uploaded_file|
      image = project.images.build
      image.file.attach(uploaded_file)
      image.save!
    end
  end

  def assign_errors_from_exception(project, exception)
    record = exception.record
    if record && record != project
      record.errors.each do |attr, message|
        project.errors.add(attr == :base ? attr : :base, message)
      end
    end
    project.errors.add(:base, exception.message) if project.errors.empty?
  end
end
