# frozen_string_literal: true

module Constructors
  class NotesController < Constructors::BaseController
    before_action :set_project
    before_action :set_noteable, only: [ :create ]
    before_action :set_note, only: [ :destroy ]

    def create
      @note = @noteable.notes.new(note_params.merge(author: current_user))
      authorize @note

      if @note.save
        # Para notas del proyecto (resumen), respondemos turbo_stream para que
        # la modal cierre y la lista se refresque sin recargar la página.
        # Para notas de etapa, el flujo sigue siendo redirect (la drawer se
        # vuelve a abrir vía Turbo Frame al recargar la stage show).
        respond_to do |format|
          format.turbo_stream do
            if @noteable.is_a?(Project)
              render turbo_stream: turbo_stream.update("project_notes_list",
                Constructors::Projects::NotesListComponent.new(
                  notes: @project.notes.recent_first.includes(:author),
                  noteable: @project,
                  project: @project
                ))
            else
              redirect_to redirect_path, notice: "Nota agregada correctamente."
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

    def set_project
      @project = current_user.owned_projects.find(params[:project_id])
    end

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
