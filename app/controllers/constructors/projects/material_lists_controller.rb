require "csv"

class Constructors::Projects::MaterialListsController < Constructors::BaseController
  helper Constructors::ProjectsHelper
  before_action :find_project!
  before_action :decorate_project
  before_action :set_material_list, only: %i[show edit update destroy toggle_publication mark_as_paid]
  before_action :set_stage_options, only: %i[new create edit update]

  def index
    authorize @project, :materials?
    @current_qb_section = :projects
    @current_qb_project = @project
    @current_qb_project_sub = :materials

    @query = params[:q].to_s.strip
    @from_date = params[:from_date].presence
    @to_date = params[:to_date].presence

    # Redesign filter chips
    @status_filter = params[:status].to_s.presence_in(MaterialList.statuses.keys.map(&:to_s)) || "all"
    @source_filter = params[:source].to_s.presence_in(MaterialList.source_types.keys.map(&:to_s)) || "all"
    @stage_filter  = params[:stage].to_s # 'all', 'none', or stage id

    @material_lists_scope = Constructors::Projects::MaterialListSearchService.new(
      project: @project,
      query: @query,
      from_date: @from_date,
      to_date: @to_date
    ).results

    @material_lists_scope = @material_lists_scope.where(status: MaterialList.statuses[@status_filter])           if @status_filter != "all"
    @material_lists_scope = @material_lists_scope.where(source_type: MaterialList.source_types[@source_filter])  if @source_filter != "all"
    @material_lists_scope = @material_lists_scope.where(project_stage_id: nil)                                   if @stage_filter == "none"
    @material_lists_scope = @material_lists_scope.where(project_stage_id: @stage_filter.to_i)                    if @stage_filter.present? && @stage_filter != "all" && @stage_filter != "none"

    @pagy, @material_lists = pagy(@material_lists_scope, limit: 25)
  end

  def show
    authorize @material_list
    @material_item = @material_list.material_items.build
    @material_items = @material_list.material_items.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.csv do
        send_data material_items_csv(@material_list),
                  filename: "materiales-#{@material_list.name.to_s.parameterize.presence || @material_list.id}-#{Date.current.strftime('%Y%m%d')}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end
  end

  def new
    authorize @project, :manage_materials?
    @material_list = @project.material_lists.build(author: current_user)
    assign_stage_from_params
  end

  def create
    authorize @project, :manage_materials?
    @material_list = @project.material_lists.build(material_list_params.merge(author: current_user))

    if @material_list.save
      if @material_list.project_stage_id.present?
        respond_to do |format|
          format.turbo_stream do
            @stage = @material_list.project_stage
            render turbo_stream: turbo_stream.update("drawer",
              partial: "constructors/projects/stages/detail_drawer",
              locals: {
                project: @project,
                stage: @stage.decorate,
                sub_stages: @stage.sub_stages.order(:position, :name),
                active_tab: :materiales
              })
          end
          format.html do
            redirect_to constructors_project_stage_path(@project, @material_list.project_stage),
                        notice: "Lista creada."
          end
        end
      else
        # Sin etapa: el POST llega frame-scoped al frame "drawer" (ya no se
        # fuerza _top en el form); Turbo sigue este redirect como una request
        # de frame y cae en material_lists#show, que ya renderiza su propio
        # detalle dentro de "drawer" — el panel pasa de "form de alta" a
        # "detalle de la lista recién creada" sin salir de la página.
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    notice: "Lista de materiales creada correctamente."
      end
    else
      flash.now[:alert] = "No pudimos crear la lista. Revisá los datos e intentá nuevamente."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @material_list
  end

  def update
    authorize @material_list

    if @material_list.update(material_list_params)
      redirect_to constructors_project_material_list_path(@project, @material_list),
                  notice: "Actualizamos la lista de materiales."
    else
      flash.now[:alert] = "No pudimos guardar los cambios. Revisá los datos e intentá nuevamente."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @material_list
    @material_list.destroy

    redirect_to constructors_project_material_lists_path(@project),
                notice: "Lista de materiales eliminada."
  end

  def toggle_publication
    authorize @material_list, :toggle_publication?

    publication = @material_list.material_list_publication ||
                  @material_list.build_material_list_publication

    if publication.visibility_public?
      publication.unpublish!
      message = "La lista ya no está habilitada para presupuestar."
    else
      publication.publish!
      message = "La lista quedó disponible para presupuestar."
    end

    redirect_to constructors_project_material_list_path(@project, @material_list), notice: message
  end

  # Registra el pago de la lista como un Expense real de la obra. "Pagada" se
  # deriva de ese vínculo (material_list_id), así que borrar el gasto la
  # desmarca sola — no hay columna de estado que se desincronice.
  def mark_as_paid
    authorize @material_list, :update?

    return redirect_back_to_list(alert: "Esta lista ya figura como pagada.") if @material_list.paid?

    total_cents = @material_list.estimated_total_cents
    return redirect_back_to_list(alert: "La lista no tiene un total estimado para pagar.") unless total_cents.positive?

    expense = @project.expenses.new(
      project_stage: @material_list.project_stage,
      material_list: @material_list,
      author: current_user,
      amount_cents: total_cents,
      currency: "ARS",
      category: :materials_misc,
      incurred_on: Date.current,
      description: "Pago lista #{@material_list.display_number} #{@material_list.name}".squish
    )
    authorize expense, :create?

    if expense.save
      redirect_back_to_list(notice: "Registramos el pago de la lista como gasto de la obra.")
    else
      redirect_back_to_list(alert: expense.errors.full_messages.to_sentence)
    end
  end

  private

  def redirect_back_to_list(**flash_opts)
    redirect_to constructors_project_material_list_path(@project, @material_list), **flash_opts
  end

  # CSV con los ítems de la lista (mismo orden que el drawer de detalle).
  # Montos en pesos (no cents) para que sea legible en Excel/Sheets.
  def material_items_csv(list)
    CSV.generate(col_sep: ";") do |csv|
      csv << [ "#", "Material", "Descripción", "Cantidad", "Unidad", "Precio unit. est. (ARS)", "Subtotal (ARS)", "Notas" ]
      list.material_items.order(created_at: :asc).each_with_index do |item, idx|
        subtotal_cents = (item.quantity.to_f * item.estimated_cost_cents.to_i).round
        csv << [
          idx + 1,
          item.name,
          item.description,
          item.quantity,
          item.unit,
          (item.estimated_cost_cents.to_i / 100.0).round(2),
          (subtotal_cents / 100.0).round(2),
          item.try(:notes)
        ]
      end
    end
  end

  def decorate_project
    @project = @project.decorate
  end

  def set_material_list
    @material_list = @project.material_lists.includes(:material_items, :project_stage).find(params[:id])
  end

  def material_list_params
    params.require(:material_list)
          .permit(:name, :notes, :status, :source_type, :source_file, :project_stage_id)
          .tap do |permitted|
            permitted[:project_stage_id] = nil if permitted[:project_stage_id].blank?
          end
  end

  def assign_stage_from_params
    return unless params[:project_stage_id].present?

    @material_list.project_stage = @project.project_stages.find_by(id: params[:project_stage_id])
  end

  def set_stage_options
    @project_stages = @project.project_stages.ordered
  end
end
