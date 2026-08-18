class Constructors::DashboardController < Constructors::BaseController
  REPORT_HEADERS = [
    "Código", "Nombre", "Estado", "Salud",
    "Avance real (%)", "Avance plan (%)", "Desvío (pp)",
    "Etapas", "Etapas finalizadas",
    "Presupuesto (ARS)", "Gastado (ARS)", "Saldo (ARS)",
    "Personas", "Documentos", "Inicio", "Fin"
  ].freeze

  REPORT_STATUS_ORDER = { "in_progress" => 0, "planned" => 1, "completed" => 2 }.freeze

  def index
    @current_qb_section = :dashboard

    months = params[:months].to_i
    months = 6 unless [ 6, 12 ].include?(months)
    @months_selected = months

    respond_to do |format|
      format.html do
        # Orden de pantalla: lo último tocado primero (obras activas + alertas).
        @projects_decorated = decorated_projects(order: { updated_at: :desc })

        @exchange_rates = External::ExchangeRatesFetcher.new.call

        # Clima de referencia para la barra superior: primero un proyecto activo
        # con coordenadas, si no hay -> Buenos Aires como default razonable.
        ref_project = current_user.accessible_projects.where.not(latitude: nil, longitude: nil).first
        if ref_project
          @reference_weather_project = ref_project
          @reference_weather_location = ref_project.location.presence || ref_project.name
          @reference_weather = External::WeatherFetcher.new(lat: ref_project.latitude, lng: ref_project.longitude).call
        else
          @reference_weather_project = nil
          @reference_weather_location = "Buenos Aires"
          @reference_weather = External::WeatherFetcher.new(lat: -34.6037, lng: -58.3816).call
        end
        service = Constructors::DashboardService.new(current_user)

        @dashboard = {
          metrics: service.send(:metrics_data),
          recent_activity: service.send(:recent_activity_entries),
          upcoming_stages: service.send(:upcoming_stages_list),
          recent_documents: service.send(:recent_documents_list),
          recent_projects: service.send(:recent_projects_list),
          evolution: service.send(:evolution_data, months_count: months)
        }

        @active_projects = @projects_decorated.reject { |p| p.status.to_s == "completed" }.first(5)
        @kpis = DashboardKpis.new(@projects_decorated).call
      end

      # "Exportar datos": volcado de la cartera para planilla. El resumen
      # presentable vive en #report.
      format.csv do
        # Orden de archivo: por nombre, estable entre descargas (updated_at
        # reordenaba el CSV cada vez que alguien tocaba una obra).
        projects = decorated_projects(order: [ :name, :id ])

        send_data projects_report_csv(projects),
                  filename: "quickbuild-obras-#{Date.current.strftime('%Y-%m-%d')}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end
  end

  # Reporte imprimible de la cartera. Es una vista HTML con @media print: el
  # navegador genera el PDF con "Guardar como PDF". Sin gemas de PDF, sin
  # Chrome headless en el dyno.
  def report
    @current_qb_section = :dashboard
    @generated_at = Time.current

    @scope_all = params[:alcance].to_s == "todas"
    # Orden de lectura del reporte: primero lo que está en obra, después lo que
    # va a empezar, al final lo cerrado. Dentro de cada grupo, alfabético.
    all_projects = decorated_projects(order: [ :name, :id ])
                   .sort_by { |p| [ REPORT_STATUS_ORDER.fetch(p.status.to_s, 9), p.name.to_s.downcase, p.id ] }

    # Por defecto el reporte muestra la cartera en curso: 34 de las 110 obras
    # de la base están finalizadas y ensucian el resumen.
    @completed_count = all_projects.count { |p| p.status.to_s == "completed" }
    @projects = @scope_all ? all_projects : all_projects.reject { |p| p.status.to_s == "completed" }

    # KPIs siempre sobre la cartera COMPLETA: "obras totales" no puede cambiar
    # según el alcance elegido para la tabla.
    @kpis = DashboardKpis.new(all_projects).call
    @spend = Exports::SpendTotals.new(all_projects.map(&:id))

    # ProjectDecorator#health marca :warn a toda obra cuyo avance real esté
    # atrás del plan, y una obra SIN etapas cargadas siempre da avance 0. Sin
    # separarlas el reporte dice "75 obras requieren atención" (67 de ellas
    # simplemente no tienen WBS): ruido, no señal. Van a un bloque propio.
    flagged = @projects.select { |p| p.health != :ok && p.status.to_s != "completed" }
    @without_plan = flagged.select { |p| p.stages_count.zero? }
    @at_risk = (flagged - @without_plan).sort_by { |p| [ p.progress - p.planned_progress, p.name.to_s ] }
  end

  # Turbo Frame endpoint for chart section
  def evolution_chart
    months = params[:months].to_i
    months = 6 unless [ 6, 12 ].include?(months)

    @months_selected = months
    service = Constructors::DashboardService.new(current_user)
    @evolution = service.send(:evolution_data, months_count: months)

    render partial: "evolution_chart_frame", locals: { evolution: @evolution, selected_months: @months_selected }
  end

  private

  # Decorated projects feed the dashboard widgets (active table + alerts),
  # the CSV export and the printable report. `includes(:project_stages)` es lo
  # que evita una query de etapas por obra en progress/stages_count/health.
  # Cartera = obras propias + donde soy miembro (mismo conjunto que
  # DashboardService, projects#index y la biblioteca). `warm_role_cache!` deja
  # los roles de todas las obras en 1 query: las cards del dashboard preguntan
  # `editable_by?` por fila.
  def decorated_projects(order:)
    projects = current_user.accessible_projects.includes(:project_stages).order(order).to_a
    Project.warm_role_cache!(current_user, projects)
    projects.map { ProjectDecorator.new(_1) }
  end

  # CSV de la cartera con los KPIs por obra. Dialecto único en
  # Exports::CsvBuilder (BOM + ";" + coma decimal + dd/mm/aaaa).
  def projects_report_csv(projects)
    ids = projects.map(&:id)
    # Sin estos tres precómputos, cada fila dispara un COUNT de personas, otro
    # de documentos y la suma de gastos: ~330 queries con 110 obras.
    people = ProjectPerson.where(project_id: ids).group(:project_id).count
    docs = Document.where(documentable_type: "Project", documentable_id: ids).group(:documentable_id).count
    spend = Exports::SpendTotals.new(ids)

    Exports::CsvBuilder.generate(REPORT_HEADERS) do |csv|
      projects.each do |p|
        spent_cents = spend.total_cents(p.id)

        csv << [
          p.code,
          p.name,
          p.status_label,
          p.health_label,
          Exports::CsvBuilder.percent(p.progress),
          Exports::CsvBuilder.percent(p.planned_progress),
          Exports::CsvBuilder.integer(p.progress - p.planned_progress),
          Exports::CsvBuilder.integer(p.stages_count),
          Exports::CsvBuilder.integer(p.stages_done),
          Exports::CsvBuilder.cents(p.budget),
          Exports::CsvBuilder.cents(spent_cents),
          Exports::CsvBuilder.cents(p.budget - spent_cents),
          Exports::CsvBuilder.integer(people[p.id].to_i),
          Exports::CsvBuilder.integer(docs[p.id].to_i),
          Exports::CsvBuilder.date(p.start_date),
          Exports::CsvBuilder.date(p.end_date)
        ]
      end
    end
  end
end
