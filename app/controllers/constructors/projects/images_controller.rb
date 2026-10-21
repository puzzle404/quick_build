class Constructors::Projects::ImagesController < Constructors::BaseController
  before_action :find_project!

  # Galería de la obra: fotos de la obra y de sus etapas, filtrables por etapa
  # (all | none = sólo de la obra | id de etapa).
  def index
    authorize @project, :show?
    @current_qb_section = :projects
    @current_qb_project = @project.decorate
    @current_qb_project_sub = :photos

    @stage_filter = params[:stage].to_s.presence || "all"
    scope = Image.for_project(@project).includes(:imageable, file_attachment: :blob).order(created_at: :desc)
    scope = scope.where(imageable_type: "Project") if @stage_filter == "none"
    scope = scope.where(imageable_type: "ProjectStage", imageable_id: @stage_filter.to_i) if @stage_filter.match?(/\A\d+\z/)
    @images = scope
  end

  # Drawer de subida: archivos primero, etapa después (opcional). Sólo vive en
  # el drawer; un GET directo vuelve a la galería.
  def new
    authorize @project, :manage_content?
    redirect_to constructors_project_images_path(@project) unless turbo_frame_request?
  end

  def create
    # Subir fotos de obra es contenido (editor+), no edición de la obra.
    authorize @project, :manage_content?

    files = Array.wrap(image_params[:files]).compact_blank
    return upload_failed("Seleccioná al menos una imagen.") if files.empty?

    # Vincular a una etapa es opcional; se busca dentro de la obra.
    target = stage_id.present? ? @project.project_stages.find(stage_id) : @project

    created = 0
    ActiveRecord::Base.transaction do
      files.each do |uploaded|
        image = target.images.build
        image.file.attach(uploaded)
        image.title ||= image.file_filename.to_s
        image.save!
        created += 1
      end
    end

    notice = created > 1 ? "#{created} imágenes cargadas." : "Imagen cargada."
    respond_to do |format|
      # Drawer: refresh (cierra el drawer y la galería muestra las fotos).
      format.turbo_stream do
        flash[:notice] = notice
        render turbo_stream: turbo_stream.refresh(request_id: nil)
      end
      format.html { redirect_to constructors_project_images_path(@project), notice: notice }
    end
  rescue ActiveRecord::RecordInvalid => e
    upload_failed("No pudimos cargar la imagen: #{e.record.errors.full_messages.to_sentence}.")
  end

  def destroy
    authorize @project, :manage_content?
    # Desde la galería también se borran fotos de etapa (siempre de esta obra).
    image = Image.for_project(@project).find(params[:id])
    image.destroy
    redirect_to constructors_project_images_path(@project), notice: "Imagen eliminada."
  end

  private

  def image_params
    params.fetch(:image, {}).permit(:title, :description, files: [])
  end

  def stage_id
    params.dig(:image, :stage_id)
  end

  # En el drawer se re-renderiza con el error (un redirect lo cerraba sin
  # mostrar nada); mobile / página completa vuelve a la galería con el aviso.
  def upload_failed(message)
    if turbo_frame_request?
      @upload_error = message
      render :new, status: :unprocessable_entity
    else
      redirect_to constructors_project_images_path(@project), alert: message
    end
  end
end
