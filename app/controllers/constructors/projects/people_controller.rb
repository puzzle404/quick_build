class Constructors::Projects::PeopleController < Constructors::BaseController
  before_action :set_project
  before_action :set_person, only: %i[show edit update destroy]

  def index
    @people = @project.project_people.order(created_at: :desc)
    authorize @people.build(project: @project)
  end

  def show
    authorize @person
    @recent_attendances = @person.person_attendances.order(occurred_at: :desc).limit(10)
  end

  def new
    @person = @project.project_people.build(status: :active)
    authorize @person
  end

  def create
    @person = @project.project_people.new(person_params)
    authorize @person
    if @person.save
      redirect_to constructors_project_person_path(@project, @person), notice: "Persona agregada a la obra."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @person
  end

  def update
    authorize @person
    if @person.update(person_params)
      redirect_to constructors_project_person_path(@project, @person), notice: "Datos actualizados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @person
    @person.destroy
    redirect_to constructors_project_people_path(@project), notice: "Persona eliminada."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_person
    @person = @project.project_people.find(params[:id])
  end

  def person_params
    params.require(:project_person).permit(:full_name, :document_id, :phone, :role_title, :status, :start_date, :end_date, :notes)
  end
end

