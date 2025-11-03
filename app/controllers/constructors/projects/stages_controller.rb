module Constructors
  module Projects
    class StagesController < Constructors::BaseController
      before_action :set_project
      before_action :set_stage, only: [:show, :edit, :update, :destroy]

      def index
        authorize @project, :show?

        @view_mode = params[:view].in?(%w[sub_stages main]) ? params[:view] : 'main'

        if @view_mode == 'sub_stages'
          @sub_stages = @project.project_stages.includes(:parent, :material_lists)
                                      .where.not(parent_id: nil)
                                      .order(:position, :name)
        else
          @stages = @project.project_stages.root.includes(:material_lists, :sub_stages)
                           .order(:position, :name)
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
          redirect_to constructors_project_stage_path(@project, @stage), notice: "Etapa creada correctamente."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        authorize @stage

        if @stage.update(stage_params)
          redirect_to constructors_project_stage_path(@project, @stage), notice: "Etapa actualizada correctamente."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @stage
        parent_stage = @stage.parent

        if @stage.destroy
          redirect_to(parent_stage.present? ? constructors_project_stage_path(@project, parent_stage) : constructors_project_stages_path(@project),
                      notice: "Etapa eliminada." )
        else
          redirect_back fallback_location: constructors_project_stages_path(@project), alert: "No pudimos eliminar la etapa."
        end
      end

      def apply_template
        authorize_new_stage!

        result = ::Constructors::Projects::StageTemplateService.call(@project)
        redirect_to constructors_project_stages_path(@project), notice: template_notice(result)
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end

      def set_stage
        @stage = @project.project_stages.includes(:documents, :material_lists, :parent, images_attachments: :blob).find(params[:id])
      end

      def stage_params
        params.require(:project_stage).permit(:name, :description, :start_date, :end_date, :parent_id)
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
        created_text = created.presence || ["sin cambios"]
        "Plantilla aplicada: #{created_text.join(' · ')}"
      end
    end
  end
end
