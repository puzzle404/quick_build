class Constructors::Projects::PeopleController < Constructors::BaseController
  # Antes: `Project.find` sin scope — era la única sección a la que llegaba
  # alguien de otra obra (y terminaba en un 500 de Pundit en vez de un 404).
  before_action :find_project!
  before_action :set_person, only: %i[show edit update destroy]

  def index
    # `:index?` (ver el equipo alcanza con acceso a la obra). Con el
    # `authorize` implícito pedía `create?` = admin de obra, así que un
    # viewer/editor no podía ni ver el listado.
    authorize @project.project_people.build, :index?
    @current_qb_section = :projects
    @project = @project.decorate
    @current_qb_project = @project
    @current_qb_project_sub = :team

    @query = params[:q].to_s.strip
    @from_date = params[:from_date].presence
    @to_date = params[:to_date].presence

    @people = Constructors::Projects::PeopleSearchService.new(
      project: @project,
      query: @query,
      from_date: @from_date,
      to_date: @to_date
    ).results

    @team_stats = TeamAttendanceStats.new(@project).call
  end

  def show
    authorize @person
    # Mismo corte que usa el update de horas para recalcular el total del pie
    # (PersonAttendance::RECENT_LIMIT): si los dos lados no listan lo mismo,
    # el total deja de cerrar con las filas que se ven.
    @recent_attendances = @person.person_attendances
                                 .recent_first
                                 .limit(PersonAttendance::RECENT_LIMIT)
                                 .to_a
  end

  def new
    @person = @project.project_people.build(status: :active)
    authorize @person
  end

  def create
    @person = @project.project_people.new(person_params)
    authorize @person
    if @person.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("project_modal", ""),
            turbo_stream.remove("people_empty_row"),
            turbo_stream.append("people_rows",
              partial: "constructors/projects/people/person_row",
              locals: { person: @person, project: @project })
          ]
        end
        format.html { redirect_to constructors_project_person_path(@project, @person), notice: "Persona agregada a la obra." }
      end
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

  def set_person
    @person = @project.project_people.find(params[:id])
  end

  def person_params
    permitted = params.require(:project_person)
                      .permit(:full_name, :document_id, :phone, :role_title, :status,
                              :start_date, :end_date, :notes,
                              :hourly_rate_cents, :hourly_rate_pesos)

    # El form tipea la tarifa en pesos (texto libre es-AR); el modelo guarda
    # centavos. Mismo patrón que projects_controller/stages_controller.
    if params[:project_person].key?(:hourly_rate_pesos)
      pesos = permitted.delete(:hourly_rate_pesos)
      permitted[:hourly_rate_cents] = pesos.present? ? Money::ArsParser.to_cents(pesos) : nil
    end

    permitted
  end
end
