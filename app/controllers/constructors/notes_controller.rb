# frozen_string_literal: true

module Constructors
  class NotesController < Constructors::BaseController
    before_action :find_project!
    before_action :set_noteable, only: [ :new, :create ]
    before_action :set_note, only: [ :destroy ]

    # Mirror of the desktop's inline modal — the Native shell hits this URL
    # so the path-config rule presents it as a bottom-sheet automatically.
    def new
      # Mismo criterio que en gastos: el form pide el permiso del alta
      # (editor+), no el de lectura.
      @note = @noteable.notes.build
      authorize @note, :new?
    end

    def create
      @note = @noteable.notes.new(note_params.merge(author: current_user))
      authorize @note

      if @note.save
        # Etapa: el form ya no fuerza _top, así que el redirect se sigue como
        # request de frame y stages#show repuebla "drawer" con el detalle
        # actualizado — mismo mecanismo que fotos/documentos/gastos de etapa.
        # Proyecto: no hay un único "detalle" al que volver, así que refresh
        # cierra el drawer y refresca la página actual (index, resumen…).
        respond_to do |format|
          format.turbo_stream do
            if request.variant.include?(:mobile) || @noteable.is_a?(ProjectStage)
              redirect_to redirect_path, notice: "Nota agregada correctamente."
            else
              flash[:notice] = "Nota agregada correctamente."
              render turbo_stream: turbo_stream.refresh(request_id: nil)
            end
          end
          format.html { redirect_to redirect_path, notice: "Nota agregada correctamente." }
        end
      else
        redirect_to redirect_path,
          alert: @note.errors.full_messages.to_sentence
      end
    end

    def destroy
      authorize @note

      @note.destroy
      redirect_to redirect_path, notice: "Nota eliminada."
    end

    private

    def set_noteable
      if params[:stage_id].present?
        @stage = @project.project_stages.find(params[:stage_id])
        @noteable = @stage
      else
        @noteable = @project
      end
    end

    def set_note
      if params[:stage_id].present?
        @stage = @project.project_stages.find(params[:stage_id])
        @note = @stage.notes.find(params[:id])
      else
        @note = @project.notes.find(params[:id])
      end
    end

    def note_params
      params.require(:note).permit(:title, :body)
    end

    def redirect_path
      if @noteable.is_a?(ProjectStage) || @stage
        constructors_project_stage_path(@project, @stage || @noteable)
      else
        constructors_project_path(@project)
      end
    end
  end
end
