require "csv"

module Constructors
  module Projects
    class StagesController < Constructors::BaseController
      before_action :find_project!
      before_action :set_stage, only: [ :show, :edit, :update, :destroy, :duplicate, :complete ]

      def index
        authorize @project, :show?
        @current_qb_section = :projects
        @project = @project.decorate
        @current_qb_project = @project
        @current_qb_project_sub = :stages
        @root_stages = @project.project_stages.where(parent_id: nil).order(:position).includes(:sub_stages)

        respond_to do |format|
          # En desktop las etapas viven en la vista unificada del proyecto
          # (projects#show); en mobile la IA es hub + pantallas, así que esta
          # pantalla sigue existiendo. El CSV se sirve en ambas variantes.
          format.html do
            redirect_to constructors_project_path(@project) unless mobile_variant?
          end
          format.csv do
            send_data stages_csv,
                      filename: "etapas-#{@project.code.to_s.downcase}-#{Date.current.strftime('%Y%m%d')}.csv",
                      type: "text/csv; charset=utf-8"
          end
        end
      end

      def show
        authorize_stage_access!
        @sub_stages = @stage.sub_stages.includes(:material_lists).order(:position, :name)
      end

      def new
        authorize_new_stage!
        @stage = @project.project_stages.build(parent_id: params[:parent_id])
        if params[:parent_id].present?
          @stage.parent = @project.project_stages.find_by(id: params[:parent_id])
        end
      end

      def edit
        authorize @stage
      end

      def create
        @stage = @project.project_stages.build(stage_params)
        authorize @stage

        if @stage.save
          respond_to do |format|
            format.turbo_stream do
              decorated_stage = @stage.decorate
              render turbo_stream: [
                turbo_stream.update("drawer", ""),
                turbo_stream.append("planning_stages",
                  Constructors::Projects::Planning::StageCardComponent.new(
                    project: @project.decorate,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
            format.html { redirect_to stages_page_path, notice: "Etapa creada correctamente." }
          end
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        authorize @stage

        if @stage.update(stage_params)
          respond_to do |format|
            format.turbo_stream do
              @stage.reload
              render turbo_stream: turbo_stream.update("drawer",
                partial: "constructors/projects/stages/detail_drawer",
                locals: {
                  project: @project.decorate,
                  stage: @stage.decorate,
                  sub_stages: @stage.sub_stages.order(:position, :name)
                })
            end
            format.html { redirect_to stages_page_path, notice: "Etapa actualizada correctamente." }
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @stage
        parent_stage = @stage.parent

        if @stage.destroy
          redirect_to(parent_stage.present? ? constructors_project_stage_path(@project, parent_stage) : stages_page_path,
                      notice: "Etapa eliminada.")
        else
          redirect_back fallback_location: stages_page_path, alert: "No pudimos eliminar la etapa."
        end
      end

      # Sin `stage_template_id` aplica la plantilla base del sistema (es lo que
      # sigue haciendo el empty state mobile). Con id, resuelve contra el scope
      # seguro: nunca StageTemplate.find directo, o se filtran rubros y
      # presupuestos de otros constructores.
      def apply_template
        authorize_new_stage!

        requested_id = params[:stage_template_id].presence
        stage_template = requested_id ? StageTemplate.available_for(current_user).find_by(id: requested_id) : nil

        if requested_id && stage_template.nil?
          return redirect_to stages_page_path, alert: "No encontramos esa plantilla."
        end

        result = ::Constructors::Projects::StageTemplateService.call(
          @project,
          template: stage_template,
          apply_dates: boolean_param(:apply_dates, default: true),
          apply_budgets: boolean_param(:apply_budgets, default: false)
        )
        redirect_to stages_page_path, notice: template_notice(result)
      end

      def duplicate
        authorize @stage, :duplicate?

        new_stage = nil

        ProjectStage.transaction do
          new_stage = @project.project_stages.create!(
            name: "#{@stage.name} (copia)",
            description: @stage.description,
            parent_id: @stage.parent_id,
            start_date: @stage.start_date,
            end_date: @stage.end_date,
            lead: @stage.try(:lead),
            budget_cents: @stage.budget_cents,
            progress: 0,
            spent_cents: 0
          )

          @stage.sub_stages.each do |sub|
            @project.project_stages.create!(
              name: sub.name,
              description: sub.description,
              parent_id: new_stage.id,
              start_date: sub.start_date,
              end_date: sub.end_date,
              lead: sub.try(:lead),
              budget_cents: sub.budget_cents,
              progress: 0,
              spent_cents: 0
            )
          end
        end

        # Etapa raíz duplicada: append turbo_stream o redirect html.
        # Sub-etapas (parent_id present): solo redirect para evitar
        # agregar un card sub-etapa al listado de etapas raíz.
        if new_stage.parent_id.nil?
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("planning_stages",
                Constructors::Projects::Planning::StageCardComponent.new(
                  project: @project.decorate,
                  stage: new_stage.decorate,
                  sub_stages: []
                ))
            end
            format.html { redirect_to stages_page_path, notice: "Etapa duplicada." }
          end
        else
          redirect_to stages_page_path, notice: "Etapa duplicada."
        end
      end

      def complete
        authorize @stage, :complete?

        if @stage.update(progress: 100)
          redirect_to constructors_project_stage_path(@project, @stage),
                      notice: "Etapa marcada como completada."
        else
          redirect_back fallback_location: constructors_project_stage_path(@project, @stage),
                        alert: "No pudimos marcar la etapa como completada."
        end
      end

      private

      # Página canónica del listado de etapas: en desktop es la vista unificada
      # del proyecto (Etapas = resumen + planificación); en mobile la pantalla
      # propia de etapas.
      def stages_page_path
        mobile_variant? ? constructors_project_stages_path(@project) : constructors_project_path(@project)
      end

      STAGES_CSV_HEADERS = [
        "WBS", "Etapa", "Etapa padre", "Estado", "Avance (%)", "Inicio", "Fin",
        "Presupuesto (ARS)", "Gastado (ARS)", "Responsable"
      ].freeze

      STAGE_STATUS_LABELS = { done: "Completada", doing: "En curso", pending: "Pendiente" }.freeze

      # CSV con la WBS completa del proyecto: etapas raíz numeradas 1, 2, …
      # y sub-etapas 1.1, 1.2, … debajo de su padre. Dialecto único en
      # Exports::CsvBuilder (BOM + ";" + coma decimal + dd/mm/aaaa).
      def stages_csv
        # `by_stage` = UNA query para todo el proyecto. "Gastado" sale de los
        # Expenses reales, igual que las cards de planificación;
        # project_stages.spent_cents es data de seed que nadie escribe.
        expense_totals = ::Projects::SpendSummary.new(@project.object).by_stage

        # `reorder` acá y no en #index: el orden del CSV tiene que ser estable
        # entre descargas y position sola empata cuando dos etapas comparten
        # posición. La vista mobile sigue con su propio @root_stages.
        roots = @root_stages.reorder(:position, :id)

        Exports::CsvBuilder.generate(STAGES_CSV_HEADERS) do |csv|
          roots.each_with_index do |stage, i|
            subs = stage.sub_stages.sort_by { |s| [ s.position.to_i, s.name.to_s, s.id ] }

            csv << stage_csv_row(stage, wbs: (i + 1).to_s, parent_name: nil,
                                 spent_cents: stage_spent_cents(expense_totals, [ stage ] + subs))
            subs.each_with_index do |sub, j|
              csv << stage_csv_row(sub, wbs: "#{i + 1}.#{j + 1}", parent_name: stage.name,
                                   spent_cents: stage_spent_cents(expense_totals, [ sub ]))
            end
          end
        end
      end

      # Las etapas raíz acumulan el gasto de sus sub-etapas (mismo roll-up que
      # StageCardComponent). Por eso la columna NO se puede sumar entera: hay
      # que filtrar por nivel de WBS.
      def stage_spent_cents(totals, stages)
        stages.sum { |s| totals[s.id].to_i }
      end

      def stage_csv_row(stage, wbs:, parent_name:, spent_cents:)
        [
          wbs,
          stage.name,
          parent_name,
          stage_status_label(stage),
          Exports::CsvBuilder.percent(stage.progress.to_i),
          Exports::CsvBuilder.date(stage.start_date),
          Exports::CsvBuilder.date(stage.end_date),
          Exports::CsvBuilder.cents(stage.budget_cents),
          Exports::CsvBuilder.cents(spent_cents),
          stage.try(:lead)
        ]
      end

      def stage_status_label(stage)
        progress = stage.progress.to_i
        return STAGE_STATUS_LABELS[:done] if progress >= 100
        return STAGE_STATUS_LABELS[:doing] if progress.positive?

        STAGE_STATUS_LABELS[:pending]
      end

      def set_stage
        @stage = @project.project_stages
                          .includes(:documents, :material_lists, :parent, images: { file_attachment: :blob })
                          .find(params[:id])
      end

      def stage_params
        permitted = params.require(:project_stage)
                          .permit(:name, :description, :start_date, :end_date, :parent_id, :predecessor_id,
                                  :progress, :lead, :budget_cents, :budget_pesos)

        # El form de etapa acepta el presupuesto en pesos (texto libre es-AR);
        # el modelo sólo guarda centavos. Mismo patrón que projects_controller.
        # key? y no present?: con `present?` un string vacío se descartaba y
        # dejaba el valor viejo, así que el presupuesto no se podía BORRAR.
        if permitted.key?(:budget_pesos)
          pesos = permitted.delete(:budget_pesos)
          permitted[:budget_cents] = pesos.present? ? Money::ArsParser.to_cents(pesos) : nil
        end

        permitted
      end

      def authorize_stage_access!
        authorize @project, :show?
      end

      def authorize_new_stage!
        authorize @project.project_stages.build, :create?
      end

      # Los checkboxes del drawer viajan como "1"/"0" (hidden + checkbox). Si
      # el param no vino (POST directo del empty state mobile) manda el default.
      def boolean_param(key, default:)
        raw = params[key]
        return default if raw.nil?

        ActiveModel::Type::Boolean.new.cast(raw).present?
      end

      def template_notice(result)
        created = []
        created << "#{result.created} etapa(s) nuevas" if result.created.positive?
        created << "#{result.sub_created} subetapa(s) nuevas" if result.sub_created.positive?
        created << "#{result.skipped} etapa(s) existentes" if result.skipped.positive?
        created << "#{result.sub_skipped} subetapa(s) existentes" if result.sub_skipped.positive?
        created.reject!(&:blank?)
        created_text = created.presence || [ "sin cambios" ]
        "Plantilla aplicada: #{created_text.join(' · ')}"
      end
    end
  end
end
