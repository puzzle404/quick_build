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
end
