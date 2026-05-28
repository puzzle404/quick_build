# frozen_string_literal: true

# Biblioteca — tabla global de documentos de todas las obras del constructor
# (a nivel proyecto y a nivel etapa). Equivalente global al listado por-proyecto
# de Constructors::Projects::DocumentsController.
class Constructors::LibraryController < Constructors::BaseController
  def index
    raise Pundit::NotAuthorizedError unless current_user&.constructor?

    @current_qb_section = :docs

    @query = params[:q].to_s.strip

    project_ids = current_user.owned_projects.pluck(:id)
    stage_ids   = ProjectStage.where(project_id: project_ids).pluck(:id)

    scope = Document.where(
      "(documentable_type = 'Project' AND documentable_id IN (:p)) OR " \
      "(documentable_type = 'ProjectStage' AND documentable_id IN (:s))",
      p: project_ids.presence || [ 0 ],
      s: stage_ids.presence || [ 0 ]
    ).includes(:documentable, file_attachment: :blob)
     .order(created_at: :desc)

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

    project_ids = current_user.owned_projects.pluck(:id)
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
end
