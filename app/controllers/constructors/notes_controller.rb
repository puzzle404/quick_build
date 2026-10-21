# frozen_string_literal: true

module Constructors
  class NotesController < Constructors::BaseController
    before_action :find_project!
    before_action :set_noteable, only: [ :new, :create ]

    # Tab "Bitácora" de la obra: nota rápida + historial completo (notas y
    # actividad). Antes vivía en el panel lateral de projects#show.
    def index
      authorize @project, :show?
      @current_qb_section = :projects
      @project = @project.decorate
      @current_qb_project = @project
      @current_qb_project_sub = :logbook
      # Obra + etapas: una nota de etapa también es parte de la bitácora.
      @notes = Note.for_project(@project.object).recent_first.includes(:author, :noteable).to_a
      @activity_entries = ::Projects::ActivitiesService.perform(@project.object)
    end
    before_action :set_note, only: [ :destroy ]

    # Única vista del form de nota: desktop la carga dentro del frame "drawer"
    # (turbo_frame "drawer" + controller Stimulus `qb--drawer`) y el shell
    # Native la abre como página completa con la variante :mobile (la regla de
    # path-config la presenta como bottom-sheet).
    def new
      # Mismo criterio que en gastos: el form pide el permiso del alta
      # (editor+), no el de lectura.
      @note = @noteable.notes.build
      authorize @note, :new?

      # `new.html.erb` entera vive detrás de `turbo_frame_request?`, así que un
      # GET directo sin frame (link pegado, historial) devolvía una página en
      # blanco. Mismo criterio que library#show: sin frame, al destino natural.
      redirect_to redirect_path unless turbo_frame_request? || mobile_variant?
    end

    def create
      @note = @noteable.notes.new(note_params.merge(author: current_user))
      authorize @note

      if @note.save
        # Ruta de etapa: el form ya no fuerza _top, así que el redirect se sigue
        # como request de frame y stages#show repuebla "drawer" con el detalle
        # actualizado — mismo mecanismo que fotos/documentos/gastos de etapa.
        # Bitácora (aunque la nota sea de una etapa): no hay un único
        # "detalle" al que volver, así que refresh cierra el drawer y refresca
        # la página actual.
        respond_to do |format|
          format.turbo_stream do
            if mobile_variant? || @stage
              redirect_to redirect_path, notice: "Nota agregada correctamente."
            else
              flash[:notice] = "Nota agregada correctamente."
              render turbo_stream: turbo_stream.refresh(request_id: nil)
            end
          end
          format.html { redirect_to redirect_path, notice: "Nota agregada correctamente." }
        end
      elsif turbo_frame_request?
        # El form vive dentro del frame "drawer". Un redirect acá lo sigue
        # Turbo como request de frame: la página de destino no tiene contenido
        # para "drawer", así que el MutationObserver de qb--drawer lo cerraba,
        # el alert se descartaba con esa respuesta y el usuario perdía lo
        # tipeado sin ver un solo mensaje. Re-renderizar el form en el lugar
        # (422) deja los errores a la vista sin salir del drawer.
        render :new, status: :unprocessable_entity
      else
        # Mobile (form de página completa, sin frame) y accesos directos: el
        # redirect + alert sí se ve porque hay navegación real.
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

    # Ruta de etapa (/stages/:stage_id/notes): nota del detalle de la etapa.
    # Ruta de la obra con note[stage_id]: nota de la Bitácora vinculada a una
    # etapa — se guarda en la etapa pero se vuelve a la Bitácora (sin @stage).
    def set_noteable
      if params[:stage_id].present?
        @stage = @project.project_stages.find(params[:stage_id])
        @noteable = @stage
      elsif (stage_id = params.dig(:note, :stage_id)).present?
        @noteable = @project.project_stages.find(stage_id)
      else
        @noteable = @project
      end
    end

    def set_note
      if params[:stage_id].present?
        @stage = @project.project_stages.find(params[:stage_id])
        @note = @stage.notes.find(params[:id])
      else
        # Desde la Bitácora también se borran notas de etapa (siempre de esta obra).
        @note = Note.for_project(@project).find(params[:id])
      end
    end

    def note_params
      params.require(:note).permit(:title, :body)
    end

    def redirect_path
      if @stage
        constructors_project_stage_path(@project, @stage, tab: "notas")
      else
        constructors_project_notes_path(@project)
      end
    end
  end
end
