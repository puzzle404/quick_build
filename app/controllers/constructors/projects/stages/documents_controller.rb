module Constructors
  module Projects
    module Stages
      class DocumentsController < Constructors::BaseController
        before_action :set_project
        before_action :set_stage
        before_action :set_document, only: :destroy

        def new
          authorize @stage, :update?
          @document = @stage.documents.build
        end

        def create
          authorize @stage, :update?

          files = Array.wrap(document_params[:files]).compact_blank

          if files.empty?
            redirect_to new_constructors_project_stage_document_path(@project, @stage), alert: "Seleccioná al menos un archivo." and return
          end

          ActiveRecord::Base.transaction do
            files.each do |file|
              record = @stage.documents.build
              record.file.attach(file)
              record.save!
            end
          end

          redirect_to constructors_project_stage_path(@project, @stage), notice: "Documento cargado correctamente."
        rescue ActiveRecord::RecordInvalid => e
          redirect_to new_constructors_project_stage_document_path(@project, @stage), alert: e.record.errors.full_messages.to_sentence
        end

        def destroy
          authorize @stage, :update?

          @document.destroy
          redirect_back fallback_location: constructors_project_stage_path(@project, @stage), notice: "Documento eliminado."
        end

        private

        def set_project
          @project = current_user.owned_projects.find(params[:project_id])
        end

        def set_stage
          @stage = @project.project_stages.find(params[:stage_id])
        end

        def set_document
          @document = @stage.documents.find(params[:id])
        end

        def document_params
          params.fetch(:document, {}).permit(files: [])
        end
      end
    end
  end
end
