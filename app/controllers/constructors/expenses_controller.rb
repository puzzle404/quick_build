# frozen_string_literal: true

module Constructors
  class ExpensesController < Constructors::BaseController
    before_action :find_project!
    before_action :set_stage, only: [ :new, :create, :destroy ]

    def index
      authorize @project, :show?
      @current_qb_section = :projects
      @project = @project.decorate
      @current_qb_project = @project
      @current_qb_project_sub = :expenses

      @category_filter = params[:category].to_s.presence_in(Expense.categories.keys) || "all"
      @stage_filter    = params[:stage].to_s # 'all', 'none' o id de etapa

      scope = @project.expenses.recent_first
      scope = scope.where(category: Expense.categories[@category_filter])            if @category_filter != "all"
      scope = scope.where(project_stage_id: nil)                                     if @stage_filter == "none"
      scope = scope.where(project_stage_id: @stage_filter.to_i)                      if stage_id_filter?

      # `::` obligatorio: dentro de `module Constructors`, `Projects::` resolvería
      # a Constructors::Projects.
      @summary = ::Projects::SpendSummary.new(@project.object)
      @expenses_count = @project.expenses.count
      @filtered_total_cents = scope.sum(:amount_cents)

      @pagy, @expenses = pagy(
        scope.includes(:author, :project_stage, :material_list).with_attached_receipt,
        limit: 25
      )
      @stage_options = @project.project_stages.order(:position, :name).pluck(:id, :name)
      @expense = Expense.new(currency: "ARS", incurred_on: Date.current)
    end

    # Renders the mobile expense form. Desktop opens the same form inline via
    # the `qb--modal` Stimulus controller; the Native shell can't host that
    # modal, so it loads `/new` instead — the path-config rule routes it as a
    # bottom-sheet automatically.
    def new
      # El formulario se autoriza como el alta que va a hacer (editor+): con
      # `:show?` un viewer llegaba hasta el form y recién ahí se comía el "no".
      @expense = @project.expenses.build(currency: "ARS", incurred_on: Date.current, project_stage: @stage)
      authorize @expense, :new?
    end

    def create
      @expense = @project.expenses.new(expense_params)
      @expense.project_stage = @stage if @stage
      @expense.author = current_user
      authorize @expense

      if @expense.save
        respond_to do |format|
          format.turbo_stream do
            if request.variant.include?(:mobile)
              redirect_to redirect_path, notice: "Gasto registrado correctamente."
            elsif @stage
              # Etapa: el form ya no fuerza _top, así que el redirect se sigue
              # como request de frame y stages#show repuebla "drawer" con el
              # detalle actualizado — mismo mecanismo que fotos/documentos.
              redirect_to redirect_path, notice: "Gasto registrado correctamente."
            else
              # Proyecto: no hay un único "detalle" al que volver (index,
              # resumen del proyecto…), así que refresh cierra el drawer y
              # refresca cualquiera de esas pantallas por igual.
              flash[:notice] = "Gasto registrado correctamente."
              render turbo_stream: turbo_stream.refresh(request_id: nil)
            end
          end
          format.html { redirect_to redirect_path, notice: "Gasto registrado correctamente." }
        end
      else
        redirect_to redirect_path,
          alert: @expense.errors.full_messages.to_sentence
      end
    end

    def destroy
      @expense = @project.expenses.find(params[:id])
      authorize @expense

      @expense.destroy
      redirect_to redirect_path, notice: "Gasto eliminado."
    end

    private

    def set_stage
      return unless params[:stage_id].present?

      @stage = @project.project_stages.find(params[:stage_id])
    end

    def stage_id_filter?
      @stage_filter.present? && @stage_filter != "all" && @stage_filter != "none"
    end

    def expense_params
      permitted = params.require(:expense).permit(
        :amount_cents, :amount_pesos, :currency, :category, :incurred_on, :description, :receipt
      )

      # Los forms postean `amount_pesos` (ARS, texto libre con inputmode=decimal).
      # Money::ArsParser respeta la convención local (coma decimal, punto de
      # miles): un gsub naive convertía "1.500,50" en $150.050 — 100x de más.
      if (pesos = permitted.delete(:amount_pesos)).present?
        permitted[:amount_cents] = Money::ArsParser.to_cents(pesos)
      end

      permitted
    end

    # Crear/borrar desde el listado de Gastos tiene que volver al listado; desde
    # el drawer de etapa, a la etapa.
    def redirect_path
      return expenses_index_path if back_to_expenses_index?
      return constructors_project_stage_path(@project, @stage) if @stage

      constructors_project_path(@project)
    end

    # El destino nunca sale del parámetro: se compara contra el path calculado
    # del index de este proyecto, así que no hay open redirect posible.
    # El borrado manda `return_to` explícito; el alta usa el form compartido de
    # expenses/new (drawer), que no puede inyectar campos extra, así que ahí
    # se resuelve por Referer.
    def back_to_expenses_index?
      return true if params[:return_to].to_s == expenses_index_path
      return false if params[:return_to].present?

      referer_path == expenses_index_path
    end

    def referer_path
      URI.parse(request.referer.to_s).path
    rescue URI::InvalidURIError
      nil
    end

    def expenses_index_path
      constructors_project_expenses_path(@project)
    end
  end
end
