require "csv"

class Constructors::ProjectsController < Constructors::BaseController
  # `find_project!(:id)`: la obra se busca en TODO lo accesible (propias +
  # donde soy miembro). Antes era `owned_projects`, así que un miembro ni
  # siquiera podía abrir la obra.
  before_action -> { find_project!(:id) }, only: %i[show edit update destroy]
  before_action :set_activity_entries, only: :show

  def show
    authorize @project
    @current_qb_section = :projects
    @project = @project.decorate
    @current_qb_project = @project
    @current_qb_project_sub = :stages

    @members = @project.members.order(created_at: :desc)
    @membership = @project.project_memberships.build
    # TODAS las etapas de la obra en UNA query, ordenadas por posición. De acá
    # salen las raíces (workspace de cards/Gantt y mapa de obra) y las
    # sub-etapas de cada una: eran dos queries, más otras dos que repetían las
    # mismas filas para el avance del header (ProjectDecorator y
    # Projects::ProgressCalculator, que ahora leen la asociación ya cargada).
    @root_stages = load_project_stages!
    # Gasto real por etapa en UNA query. Lo consume StageCardComponent para el
    # bloque GASTOS (con roll-up de sub-etapas) sin pegarle a la base por card.
    @stage_expense_totals = Projects::SpendSummary.new(@project.object).by_stage
    # Idem con documentos, fotos y listas de materiales: tres queries agrupadas
    # para toda la obra en lugar de tres por tarjeta y tres por sub-etapa.
    @stage_counts = Projects::StageCounts.for_project(@project.object)
    @recent_documents = @project.documents.order(created_at: :desc).limit(6)
    @weather_forecast = External::WeatherFetcher.new(lat: @project.latitude, lng: @project.longitude).call
  end

  def index
    @current_qb_section = :projects

    @query = params[:q].to_s.strip
    @from_date = params[:from_date].presence
    @to_date = params[:to_date].presence
    @status_filter = params[:status].to_s.presence_in(%w[in_progress planned completed]) || "all"

    # El listado son las obras en las que trabajo: las mías + donde soy
    # miembro. `owned_projects` acá dejaba las membresías sin ninguna puerta
    # de entrada visible.
    base_scope = current_user.accessible_projects
    base_scope = base_scope.where(status: Project.statuses[@status_filter]) if @status_filter != "all"

    @projects_scope = Constructors::Projects::ProjectSearchService.new(
      scope: base_scope,
      query: @query,
      from_date: @from_date,
      to_date: @to_date
    ).results

    respond_to do |format|
      format.html do
        @pagy, @projects = pagy(@projects_scope, limit: 25)
        # Una query para los roles de toda la página: las cards preguntan
        # `editable_by?`/`owned_by?` por fila y sin esto sería un N+1.
        Project.warm_role_cache!(current_user, @projects)
        @projects_decorated = @projects.map { ProjectDecorator.new(_1) }
        # Los contadores de los chips tienen que contar lo MISMO que lista la
        # tabla, si no "Todas (3)" con 5 filas.
        @counts = current_user.accessible_projects.group(:status).count
        @counts_total = @counts.values.sum
      end
      format.csv do
        send_data projects_csv(@projects_scope),
                  filename: "proyectos-#{Date.current.strftime('%Y%m%d')}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end
  end

  def new
    @current_qb_section = :projects
    @project = current_user.owned_projects.build
    authorize @project
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    authorize @project

    if persist_project_with_documents(@project)
      flash[:new_project] = true
      flash[:notice] = "¡Obra creada correctamente!"
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_path(@project)
          else
            # Única excepción de las 18 migradas: crear una obra abandona por
            # completo el contexto actual (sidebar, obra activa, etc.), así
            # que un patch in-place del frame "drawer" no alcanza — hace
            # falta una navegación real de página. El flash ya quedó seteado
            # en esta respuesta y se muestra en la página de destino.
            render turbo_stream: turbo_stream.action(:redirect, constructors_project_path(@project))
          end
        end
        format.html { redirect_to constructors_project_path(@project) }
      end
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

    if params[:featured_image].present?
      image = @project.images.new(file: params[:featured_image], featured: true)
      begin
        ActiveRecord::Base.transaction do
          @project.images.where(featured: true).update_all(featured: false)
          image.save!
        end
        return redirect_to constructors_project_path(@project), notice: "Portada actualizada."
      rescue ActiveRecord::RecordInvalid
        return redirect_to constructors_project_path(@project), alert: image.errors.full_messages.to_sentence
      end
    end

    @project.assign_attributes(project_params)

    if persist_project_with_documents(@project)
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente."
          else
            render turbo_stream: turbo_stream.refresh(request_id: nil)
          end
        end
        format.html { redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente." }
      end
    else
      @project_summary = @project.decorate
      flash.now[:alert] = "No pudimos guardar los cambios. Revisa los datos e inténtalo otra vez."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Borrar la obra es exclusivo del owner (ProjectPolicy#destroy?): un admin
    # de obra gestiona el equipo y los datos, pero no la hace desaparecer.
    authorize @project

    @project.destroy
    redirect_to constructors_projects_path, notice: "Obra eliminada.", status: :see_other
  end

  private

  # Etapas raíz con sub-etapas eager-loaded (2 queries) + el resto del árbol
  # cableado en memoria, para que nadie más vuelva a leer estas mismas filas:
  #
  #   * `parent` queda cargada en cada sub-etapa —cosa que `includes` NO hace—,
  #     así el código "2.1" de ProjectStageDecorator deja de pedir la raíz de a
  #     una fila (card y Gantt);
  #   * `project_stages` del proyecto queda marcada como cargada, así el
  #     decorator (avance / gasto del header) y Projects::ProgressCalculator
  #     reusan estas filas en vez de repetir el SELECT.
  #
  # El árbol es de dos niveles por diseño (ProjectStage#parent_must_be_root, más
  # la FK de parent_id), así que raíces + sub-etapas son TODAS las etapas de la
  # obra: la asociación queda completa, no recortada.
  #
  # OJO con "optimizar" esto a una sola query que traiga todo y filtre las
  # raíces en Ruby: hay obras con varias raíces en la misma `position` y, con
  # empates, Postgres ordena distinto según qué filas entren en el SELECT. Se
  # reordenaban las tarjetas en pantalla.
  def load_project_stages!
    roots = @project.project_stages.where(parent_id: nil).order(:position).includes(:sub_stages).to_a

    sub_stages = roots.flat_map do |root|
      root.sub_stages.each { |sub| sub.association(:parent).target = root }
    end

    @project.object.association(:project_stages).target = roots + sub_stages

    roots
  end

  # CSV del listado de obras (respeta filtros de estado/búsqueda/fechas).
  def projects_csv(scope)
    CSV.generate(headers: true) do |csv|
      csv << [ "Código", "Nombre", "Cliente", "Ubicación", "Estado", "Inicio", "Fin estimado",
               "Avance físico (%)", "Avance plan (%)", "Presupuesto (ARS)", "Gastado (ARS)" ]
      scope.each do |project|
        decorated = ProjectDecorator.new(project)
        csv << [ decorated.code, project.name, project.client, project.location, decorated.status_label,
                 project.start_date, project.end_date, decorated.progress, decorated.planned_progress,
                 (project.budget_cents.to_i / 100.0).round(2), (decorated.spent.to_i / 100.0).round(2) ]
      end
    end
  end

  def project_params
    permitted = params.require(:project)
                      .permit(:name, :client, :description, :location, :start_date, :end_date, :status,
                              :budget_cents, :budget_pesos, :latitude, :longitude, document_files: [])

    # Mobile form posts `budget_pesos` (ARS); convert to cents and drop the
    # pesos key so it doesn't reach the model (which only has budget_cents).
    # key? y no present?: con `present?` un string vacío se descartaba y dejaba
    # el valor viejo, así que el presupuesto de la obra no se podía BORRAR.
    if permitted.key?(:budget_pesos)
      pesos = permitted.delete(:budget_pesos)
      permitted[:budget_cents] = pesos.present? ? Money::ArsParser.to_cents(pesos) : nil
    end

    permitted
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
