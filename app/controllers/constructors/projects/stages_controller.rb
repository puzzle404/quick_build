module Constructors
  module Projects
    class StagesController < Constructors::BaseController
      before_action :set_project
      before_action :set_stage, only: :destroy

      def create
        @stage = @project.project_stages.build(stage_params)
        authorize @stage

        respond_to do |format|
          if @stage.save
            format.turbo_stream
            format.html { redirect_to constructors_project_planning_path(@project), notice: "Etapa creada correctamente." }
          else
            format.turbo_stream { render :create, status: :unprocessable_entity }
            format.html { redirect_to constructors_project_planning_path(@project), alert: @stage.errors.full_messages.to_sentence }
          end
        end
      end

      def destroy
        authorize @stage

        respond_to do |format|
          if @stage.destroy
            format.turbo_stream
            format.html { redirect_to constructors_project_planning_path(@project), notice: "Etapa eliminada." }
          else
            format.html { redirect_to constructors_project_planning_path(@project), alert: "No pudimos eliminar la etapa." }
          end
        end
      end

      private

      def set_project
        @project = current_user.owned_projects.find(params[:project_id])
      end

      def set_stage
        @stage = @project.project_stages.find(params[:id])
      end

      def stage_params
        params.require(:project_stage).permit(:name, :description, :start_date, :end_date)
      end
    end
  end
end
