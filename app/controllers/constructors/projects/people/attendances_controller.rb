class Constructors::Projects::People::AttendancesController < Constructors::BaseController
  before_action :find_project!
  before_action :set_person
  before_action :set_attendance, only: %i[update destroy]

  # Dar presente es de UN click y sin formulario: se marca parado en la obra.
  # Las horas NO se piden acá (ni se asume una jornada de 8 — sería fabricar
  # el dato): se cargan después con #update, cuando la jornada terminó.
  def create
    attendance = @person.person_attendances.new(attendance_params.merge(occurred_at: Time.current))
    authorize attendance

    if attendance.save
      # TODO: Notificar al constructor (servicio/async cuando esté disponible)
      redirect_to person_page_path, notice: "Presente registrado."
    else
      redirect_to person_page_path, alert: "No se pudo registrar el presente."
    end
  end

  # Carga de horas sobre una marca que ya existe, una fila a la vez desde la
  # tabla de asistencias de la ficha de persona.
  def update
    authorize @attendance

    if @attendance.update(hours_params)
      respond_with_row(notice: "Horas actualizadas.")
    else
      # 422 + la fila re-renderizada con el valor tipeado y el error debajo:
      # sin esto la fila vuelve al valor viejo sin ninguna explicación.
      respond_with_row(alert: hours_error_message, status: :unprocessable_entity)
    end
  end

  def destroy
    authorize @attendance
    @attendance.destroy
    redirect_to person_page_path, notice: "Marca de asistencia eliminada.", status: :see_other
  end

  private

  def set_person
    @person = @project.project_people.find(params[:person_id])
  end

  def set_attendance
    @attendance = @person.person_attendances.find(params[:id])
  end

  def attendance_params
    params.fetch(:person_attendance, {}).permit(:latitude, :longitude, :notes, :source)
  end

  # `key?` y no `.present?`: si se borra el contenido del input el param llega
  # como "" y TIENE que limpiar las horas (el setter del modelo lo pasa a
  # nil). Con `.present?` el string vacío no borraría nada y un dato mal
  # cargado quedaría pegado para siempre. Sin la clave no se toca nada.
  def hours_params
    permitted = params.fetch(:person_attendance, {}).permit(:hours)
    return {} unless permitted.key?(:hours)

    { hours: permitted[:hours] }
  end

  # `full_messages` no sirve acá: prefijaría el nombre del atributo en inglés
  # ("Hours ...") porque es-AR.yml no traduce los atributos de este modelo.
  def hours_error_message
    messages = @attendance.errors[:hours]
    return "No se pudieron guardar las horas." if messages.empty?

    "Horas: #{messages.to_sentence}"
  end

  # Responde con la fila recalculada + el total del pie: el total depende de
  # todas las filas listadas, así que no alcanza con reemplazar una.
  def respond_with_row(notice: nil, alert: nil, status: :ok)
    @recent_attendances = @person.person_attendances
                                 .recent_first
                                 .limit(PersonAttendance::RECENT_LIMIT)
                                 .to_a

    respond_to do |format|
      format.turbo_stream { render :update, status: status }
      format.html { redirect_to person_page_path, notice: notice, alert: alert }
    end
  end

  def person_page_path
    constructors_project_person_path(@project, @person)
  end
end
