module Constructors
  module Projects
    class StagesController < Constructors::BaseController
      before_action :set_project
      before_action :set_stage, only: [ :show, :edit, :update, :destroy, :duplicate, :complete ]

      def index
        authorize @project, :show?
        @current_qb_section = :projects
        @project = @project.decorate
        @current_qb_project = @project
        @current_qb_project_sub = :planning
        @root_stages = @project.project_stages.where(parent_id: nil).order(:position).includes(:sub_stages)
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
                turbo_stream.update("project_modal", ""),
                turbo_stream.append("planning_stages",
                  Constructors::Projects::Planning::StageCardComponent.new(
                    project: @project.decorate,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
            format.html { redirect_to constructors_project_stages_path(@project), notice: "Etapa creada correctamente." }
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
              decorated_stage = @stage.decorate
              decorated_project = @project.decorate
              render turbo_stream: [
                turbo_stream.update("project_modal", ""),
                turbo_stream.update("stage_detail",
                  Constructors::Projects::Planning::StageDetailComponent.new(
                    project: decorated_project,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
            format.html { redirect_to constructors_project_stages_path(@project), notice: "Etapa actualizada correctamente." }
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @stage
        parent_stage = @stage.parent

        if @stage.destroy
          redirect_to(parent_stage.present? ? constructors_project_stage_path(@project, parent_stage) : constructors_project_stages_path(@project),
                      notice: "Etapa eliminada.")
        else
          redirect_back fallback_location: constructors_project_stages_path(@project), alert: "No pudimos eliminar la etapa."
        end
      end

      def apply_template
        authorize_new_stage!

        result = ::Constructors::Projects::StageTemplateService.call(@project)
        redirect_to constructors_project_stages_path(@project), notice: template_notice(result)
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
            format.html { redirect_to constructors_project_stages_path(@project), notice: "Etapa duplicada." }
          end
        else
          redirect_to constructors_project_stages_path(@project), notice: "Etapa duplicada."
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

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end

      def set_stage
        @stage = @project.project_stages
                          .includes(:documents, :material_lists, :parent, images: { file_attachment: :blob })
                          .find(params[:id])
      end

      def stage_params
        params.require(:project_stage).permit(:name, :description, :start_date, :end_date, :parent_id, :predecessor_id)
      end

      def authorize_stage_access!
        authorize @project, :show?
      end

      def authorize_new_stage!
        authorize @project.project_stages.build, :create?
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
