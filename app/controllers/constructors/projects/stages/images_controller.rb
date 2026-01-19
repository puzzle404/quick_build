module Constructors
  module Projects
    module Stages
      class ImagesController < Constructors::BaseController
        before_action :set_project
        before_action :set_stage
        before_action :set_image, only: :destroy

        def new
          authorize @stage, :update?
        end

        def create
          authorize @stage, :update?

          files = Array.wrap(image_params[:files]).compact_blank

          if files.empty?
            redirect_to new_constructors_project_stage_image_path(@project, @stage), alert: "Seleccioná al menos una imagen." and return
          end

          ActiveRecord::Base.transaction do
            files.each do |uploaded|
              image = @stage.images.build
              image.file.attach(uploaded)
              image.title ||= image.file_filename.to_s
              image.save!
            end
          end

          redirect_to constructors_project_stage_path(@project, @stage), notice: "Imágenes cargadas correctamente."
        rescue ActiveRecord::RecordInvalid => e
          redirect_to new_constructors_project_stage_image_path(@project, @stage), alert: "No pudimos cargar las imágenes: #{e.record.errors.full_messages.to_sentence}."
        end

        def destroy
          authorize @stage, :update?

          @image.purge
          redirect_back fallback_location: constructors_project_stage_path(@project, @stage), notice: "Imagen eliminada."
        end

        private

        def set_project
          @project = current_user.owned_projects.find(params[:project_id])
        end

        def set_stage
          @stage = @project.project_stages.find(params[:stage_id])
        end

        def set_image
          @image = @stage.images.find(params[:id])
        end

        def image_params
          params.fetch(:image, {}).permit(files: [])
        end
      end
    end
  end
end
