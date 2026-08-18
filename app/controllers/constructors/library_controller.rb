# frozen_string_literal: true

# Biblioteca — tabla global de documentos de todas las obras del constructor
# (a nivel proyecto y a nivel etapa). Equivalente global al listado por-proyecto
# de Constructors::Projects::DocumentsController.
class Constructors::LibraryController < Constructors::BaseController
  TYPE_FILTERS = %w[pdf image sheet doc other].freeze
  SHEET_CONTENT_TYPES = [
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/csv"
  ].freeze
  DOC_CONTENT_TYPES = [
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ].freeze

  def index
    raise Pundit::NotAuthorizedError unless current_user&.constructor?

    @current_qb_section = :docs

    @query = params[:q].to_s.strip
    @type_filter = params[:type].to_s.presence_in(TYPE_FILTERS) || "all"

    # Biblioteca = documentos de las obras en las que trabajo, no sólo las
    # mías. El filtro por obra y el scope de documentos salen del MISMO
    # conjunto: si divergen, el filtro deja pedir ids que la tabla no muestra.
    @projects_for_filter = current_user.accessible_projects.order(:name)
    project_ids = @projects_for_filter.pluck(:id)
    @project_filter = params[:project_id].to_s.presence_in(project_ids.map(&:to_s)) || "all"

    filtered_project_ids = @project_filter == "all" ? project_ids : [ @project_filter.to_i ]
    stage_ids = ProjectStage.where(project_id: filtered_project_ids).pluck(:id)

    scope = Document.where(
      "(documentable_type = 'Project' AND documentable_id IN (:p)) OR " \
      "(documentable_type = 'ProjectStage' AND documentable_id IN (:s))",
      p: filtered_project_ids.presence || [ 0 ],
      s: stage_ids.presence || [ 0 ]
    ).includes(:documentable, file_attachment: :blob)
     .order(created_at: :desc)

    scope = apply_type_filter(scope, @type_filter)

    if @query.present?
      matching_ids = Document.search_text(@query).select(:id)
      scope = scope.where(id: matching_ids)
    end

    @pagy, @documents = pagy(scope, limit: 30)
  end

  # Visor embebido del documento. La index linkea a esta acción con
  # data-turbo-frame="project_modal" — el visor se abre en un drawer QB OS
  # con un <iframe> al archivo (PDFs/imágenes el browser los muestra inline).
  def show
    raise Pundit::NotAuthorizedError unless current_user&.constructor?

    project_ids = current_user.accessible_projects.pluck(:id)
    stage_ids   = ProjectStage.where(project_id: project_ids).pluck(:id)

    @document = Document.where(
      "(documentable_type = 'Project' AND documentable_id IN (:p)) OR " \
      "(documentable_type = 'ProjectStage' AND documentable_id IN (:s))",
      p: project_ids.presence || [ 0 ],
      s: stage_ids.presence || [ 0 ]
    ).includes(:documentable, file_attachment: :blob).find(params[:id])

    # Acceso directo (no frame): redirigir al archivo. El visor modal solo
    # tiene sentido cuando la index lo carga vía Turbo Frame.
    redirect_to url_for(@document.file), allow_other_host: true unless turbo_frame_request?
  end

  private

  # Filtro "Tipo" del toolbar — agrupa por content_type del blob adjunto.
  # Se filtra vía subquery sobre attachments (no join directo) para no chocar
  # con el includes(:documentable) polimórfico del scope principal.
  def apply_type_filter(scope, type)
    return scope if type == "all"

    attachments = ActiveStorage::Attachment.joins(:blob).where(record_type: "Document", name: "file")
    attachments =
      case type
      when "pdf"   then attachments.where(active_storage_blobs: { content_type: "application/pdf" })
      when "image" then attachments.where("active_storage_blobs.content_type LIKE 'image/%'")
      when "sheet" then attachments.where(active_storage_blobs: { content_type: SHEET_CONTENT_TYPES })
      when "doc"   then attachments.where(active_storage_blobs: { content_type: DOC_CONTENT_TYPES })
      when "other"
        attachments.where.not(active_storage_blobs: { content_type: [ "application/pdf" ] + SHEET_CONTENT_TYPES + DOC_CONTENT_TYPES })
                   .where("active_storage_blobs.content_type NOT LIKE 'image/%'")
      end

    scope.where(id: attachments.select(:record_id))
  end
end
