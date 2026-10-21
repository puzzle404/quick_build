class Constructors::Projects::DocumentsController < Constructors::BaseController
  before_action :find_project!

  def index
    authorize @project, :show?
    @current_qb_section = :projects
    @project = @project.decorate
    @current_qb_project = @project
    @current_qb_project_sub = :docs

    @query = params[:q].to_s.strip
    @from_date = params[:from_date].presence
    @to_date = params[:to_date].presence

    @documents = Constructors::Projects::DocumentSearchService.new(
      project: @project,
      query: @query,
      from_date: @from_date,
      to_date: @to_date
    ).results
  end

  # Drawer de subida: archivos primero, etapa después (opcional). Sólo vive en
  # el drawer; un GET directo vuelve a la pestaña.
  def new
    authorize @project, :manage_content?
    redirect_to constructors_project_documents_path(@project) unless turbo_frame_request?
  end

  def create
    # `:manage_content?` (editor+) y no `:update?` (admin+): subir documentos
    # es cargar contenido de obra, no editar los datos de la obra.
    authorize @project, :manage_content?

    files = Array.wrap(document_params[:files]).compact_blank
    return upload_failed("Seleccioná al menos un archivo.") if files.empty?

    # Vincular a una etapa es opcional; se busca dentro de la obra.
    target = stage_id.present? ? @project.project_stages.find(stage_id) : @project
    created_count = 0

    ActiveRecord::Base.transaction do
      files.each do |file|
        document = target.documents.build
        document.file.attach(file)
        document.save!
        created_count += 1
      end
    end

    message = created_count > 1 ? "#{created_count} documentos subidos correctamente." : "Documento subido correctamente."
    respond_to do |format|
      # Drawer: refresh (cierra el drawer y la pestaña muestra los documentos).
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.refresh(request_id: nil)
      end
      format.html { redirect_to constructors_project_documents_path(@project), notice: message }
    end
  rescue ActiveRecord::RecordInvalid => e
    upload_failed("No pudimos adjuntar el documento: #{e.record.errors.full_messages.to_sentence}.")
  end

  def destroy
    authorize @project, :manage_content?
    # Desde la pestaña también se borran documentos de etapa (siempre de esta obra).
    document = Document.for_project(@project).find(params[:id])
    document.destroy

    redirect_to constructors_project_documents_path(@project), notice: "Documento eliminado."
  end

  private

  def document_params
    params.fetch(:document, {}).permit(files: [])
  end

  def stage_id
    params.dig(:document, :stage_id)
  end

  # En el drawer se re-renderiza con el error (un redirect lo cerraba sin
  # mostrar nada); mobile / página completa vuelve a la pestaña con el aviso.
  def upload_failed(message)
    if turbo_frame_request?
      @upload_error = message
      render :new, status: :unprocessable_entity
    else
      redirect_to constructors_project_documents_path(@project), alert: message
    end
  end
end
