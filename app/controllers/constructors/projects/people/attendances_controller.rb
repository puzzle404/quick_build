class Constructors::Projects::People::AttendancesController < Constructors::BaseController
  before_action :set_project
  before_action :set_person

  def create
    attendance = @person.person_attendances.new(attendance_params.merge(occurred_at: Time.current))
    authorize attendance

    if attendance.save
      # TODO: Notificar al constructor (servicio/async cuando esté disponible)
      redirect_to constructors_project_person_path(@project, @person), notice: "Presente registrado."
    else
      redirect_to constructors_project_person_path(@project, @person), alert: "No se pudo registrar el presente."
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_person
    @person = @project.project_people.find(params[:person_id])
  end

  def attendance_params
    params.fetch(:person_attendance, {}).permit(:latitude, :longitude, :notes, :source)
  end
end

