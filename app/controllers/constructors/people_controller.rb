# frozen_string_literal: true

# Global Personas screen — cross-project view of every team member the
# constructor has across their owned projects. Mirrors team.jsx from the
# Claude Design handoff. Per-project people management still lives under
# Constructors::Projects::PeopleController.
class Constructors::PeopleController < Constructors::BaseController
  ATTENDANCE_WINDOW_DAYS = 30

  def index
    authorize :people, :index_global?
    @current_qb_section = :team

    @query = params[:q].to_s.strip.downcase

    # Project-people across all owned projects, decorated for the table.
    base = ProjectPerson.joins(:project)
                        .where(projects: { owner_id: current_user.id })
                        .includes(:project)

    base = base.where("LOWER(full_name) LIKE ?", "%#{@query}%") if @query.present?

    rows = base.to_a

    # Todas las marcas de asistencia que necesitan las métricas, en UNA sola
    # query. Antes eran 2 queries por fila agrupada + 2 por persona en los
    # KPIs (N+1); ahora se filtran en memoria por ventana.
    stamps_by_person = attendance_stamps_by_person(rows)

    # Group by (full_name, phone) so the same person on N projects becomes
    # one row with N "Asignada a" pills.
    @grouped = rows.group_by { |p| [ p.full_name, p.phone ] }.map do |key, ppl|
      first = ppl.first
      stamps = ppl.flat_map { |p| stamps_by_person[p.id] || [] }
      {
        person_id:        first.id,
        full_name:        first.full_name,
        phone:            first.phone,
        role_title:       first.role_title,
        document_id:      first.document_id,
        status:           ppl.any? { |p| p.status.to_s == "active" } ? "active" : "inactive",
        hourly_rate_cents: ppl.map { |p| p.try(:hourly_rate_cents) }.compact.max,
        projects:         ppl.map(&:project).uniq,
        attendance_days:  attendance_days_from(stamps),
        attendance_pct:   attendance_pct_from(stamps)
      }
    end

    # Pagy::Backend's pagy_array isn't always loaded by the array extra; use
    # Pagy.new directly + Array#slice — same shape (pagy, page_items).
    page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY).to_i
    limit = 25
    @pagy = Pagy.new(count: @grouped.size, page: page, limit: limit)
    @grouped_page = @grouped.slice((page - 1) * limit, limit) || []

    @kpis = compute_kpis(rows, stamps_by_person)
  end

  # Vista global de una persona: consolida todas sus asignaciones (mismo
  # nombre + teléfono) across las obras del constructor. El id es el de
  # cualquiera de sus ProjectPerson (fila representativa).
  def show
    authorize :people, :index_global?
    @current_qb_section = :team

    set_person
    @assignments = siblings_of(@person)
    @attendances = PersonAttendance.where(project_person_id: @assignments.map(&:id))
                                   .includes(project_person: :project)
                                   .order(occurred_at: :desc)
                                   .limit(15)
    @stats = person_stats(@assignments)
    @days_by_assignment = attendance_days_by_assignment(@assignments)
  end

  def edit
    authorize :people, :index_global?
    @current_qb_section = :team

    set_person
    @assignments = siblings_of(@person)
  end

  # Edita los datos de identidad (nombre, teléfono, documento) y los propaga
  # a TODAS las asignaciones de la persona — son N filas de project_people
  # que representan a la misma persona física.
  def update
    authorize :people, :index_global?
    set_person
    @assignments = siblings_of(@person)

    ActiveRecord::Base.transaction do
      @assignments.each { |a| a.update!(person_params) }
    end

    notice = "Datos actualizados en #{@assignments.size} #{@assignments.size == 1 ? 'asignación' : 'asignaciones'}."
    respond_to do |format|
      format.turbo_stream do
        if request.variant.include?(:mobile)
          redirect_to constructors_person_path(@person), notice: notice
        else
          render turbo_stream: turbo_stream.refresh(request_id: nil)
        end
      end
      format.html { redirect_to constructors_person_path(@person), notice: notice }
    end
  rescue ActiveRecord::RecordInvalid => e
    @current_qb_section = :team
    @person.assign_attributes(person_params)
    @person.validate
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end

  private

  def set_person
    @person = ProjectPerson.joins(:project)
                           .where(projects: { owner_id: current_user.id })
                           .find(params[:id])
  end

  # Las asignaciones de una misma persona se agrupan por (nombre, teléfono).
  # Sin teléfono la clave no distingue homónimos, así que la ficha se limita a
  # esa asignación: agrupar por nombre solo mezclaría dos personas distintas y
  # el update pisaría los datos de la equivocada.
  def siblings_of(person)
    return [ person ] if person.phone.blank?

    ProjectPerson.joins(:project)
                 .where(projects: { owner_id: current_user.id })
                 .where(full_name: person.full_name, phone: person.phone)
                 .includes(:project)
                 .sort_by { |a| a.project.name.to_s }
  end

  def person_params
    params.require(:project_person).permit(:full_name, :phone, :document_id)
  end

  def person_stats(assignments)
    ids = assignments.map(&:id)
    hours = PersonAttendance.where(project_person_id: ids)
                            .where(occurred_at: 30.days.ago.beginning_of_day..Time.current.end_of_day)
                            .sum(:hours)
    {
      projects_count: assignments.map(&:project_id).uniq.size,
      active_count: assignments.count { |a| a.status.to_s == "active" },
      attendance_pct: attendance_pct_for(assignments),
      attendance_days: attendance_days_for(assignments),
      # Denominador de la asistencia: sin él el porcentaje no se puede leer
      # ("30%" de qué). La ficha lo muestra como "N de M días hábiles".
      business_days: attendance_business_days,
      # hours_30d sigue calculándose porque lo consume la variante mobile; la
      # ficha desktop dejó de mostrarlo (0 de 6 asistencias tienen horas).
      hours_30d: hours.to_f.positive? ? hours.to_f.round(1) : nil,
      hourly_rate_cents: assignments.map { |a| a.hourly_rate_cents }.compact.max
    }
  end

  # Días con marca en el mes en curso, por asignación: es la única forma de ver
  # en qué obra estuvo la persona cuando tiene varias (7 de 14 tienen 6).
  def attendance_days_by_assignment(assignments)
    stamps = attendance_stamps_by_person(assignments)
    assignments.to_h { |a| [ a.id, distinct_days(stamps[a.id] || [], attendance_windows[:month]) ] }
  end

  # No Pundit policy class for ":people" symbol — we authorize via base. If
  # the user is a constructor (BaseController#ensure_constructor!), let
  # them in. Anything else 403.
  def authorize(*); current_user&.constructor? || raise(Pundit::NotAuthorizedError); end

  # Las dos ventanas de asistencia, resueltas una sola vez por request para
  # que todas las filas usen exactamente los mismos límites.
  #
  # OJO con el borde inferior de :month — el código original pasaba un Date a
  # la query, y Postgres lo compara contra la columna `timestamp` (que guarda
  # UTC) como medianoche UTC, no como medianoche local. Se conserva tal cual
  # (`to_time(:utc)`) para no mover los números.
  def attendance_windows
    @attendance_windows ||= begin
      upper = Time.current.end_of_day
      {
        month: Date.current.beginning_of_month.to_time(:utc)..upper,
        pct:   ATTENDANCE_WINDOW_DAYS.days.ago.beginning_of_day..upper
      }
    end
  end

  def attendance_business_days
    @attendance_business_days ||=
      (ATTENDANCE_WINDOW_DAYS.days.ago.to_date..Date.current).count { |d| ![ 0, 6 ].include?(d.wday) }
  end

  # {project_person_id => [occurred_at, ...]} para la unión de ambas ventanas,
  # en una sola query. El recorte exacto por ventana lo hace #distinct_days.
  def attendance_stamps_by_person(people)
    ids = people.map(&:id).uniq
    return {} if ids.empty?

    windows = attendance_windows
    lower = [ windows[:month].begin, windows[:pct].begin ].min
    PersonAttendance.where(project_person_id: ids)
                    .where(occurred_at: lower..windows[:month].end)
                    .pluck(:project_person_id, :occurred_at)
                    .group_by(&:first)
                    .transform_values { |pairs| pairs.map(&:last) }
  end

  def distinct_days(stamps, window)
    stamps.select { |at| window.cover?(at) }.map(&:to_date).uniq.size
  end

  def attendance_days_from(stamps)
    distinct_days(stamps, attendance_windows[:month])
  end

  def attendance_pct_from(stamps)
    return nil if attendance_business_days.zero?
    (distinct_days(stamps, attendance_windows[:pct]).to_f / attendance_business_days * 100).round
  end

  # Camino de #show/#edit/#update: una sola persona (con sus N asignaciones),
  # así que una query alcanza.
  def attendance_stamps_for(people)
    attendance_stamps_by_person(people).values.flatten
  end

  def attendance_days_for(people)
    attendance_days_from(attendance_stamps_for(people))
  end

  def attendance_pct_for(people)
    attendance_pct_from(attendance_stamps_for(people))
  end

  def compute_kpis(rows, stamps_by_person)
    active = rows.count { |p| p.status.to_s == "active" }
    on_leave = rows.count { |p| p.status.to_s == "inactive" }

    # Promedio POR ProjectPerson (no por fila agrupada) — mismo criterio que
    # el `rows.group_by(&:id).keys` original.
    pcts = rows.map(&:id).uniq.map { |id| attendance_pct_from(stamps_by_person[id] || []) }.compact
    avg_attendance = pcts.empty? ? nil : (pcts.sum.to_f / pcts.size).round

    cost_cents = PersonAttendance.joins(:project_person)
                                 .where(project_people: { id: rows.map(&:id) })
                                 .where.not(hours: nil)
                                 .where.not(project_people: { hourly_rate_cents: nil })
                                 .where(occurred_at: Date.current.beginning_of_month..Time.current.end_of_day)
                                 .pluck(:hours, "project_people.hourly_rate_cents")
                                 .sum { |h, rate| (h.to_f * rate.to_i).round }

    {
      total: rows.size,
      active: active,
      on_leave: on_leave,
      avg_attendance_pct: avg_attendance,
      labor_cost_cents: cost_cents.zero? ? nil : cost_cents
    }
  end
end
