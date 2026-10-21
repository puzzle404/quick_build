class Document < ApplicationRecord
  include PgSearch::Model
  belongs_to :documentable, polymorphic: true

  has_one_attached :file
  has_one :file_blob, through: :file_attachment, source: :blob

  validates :file, presence: true

  # Documentos de la obra y de todas sus etapas: la pestaña Documentos los
  # muestra todos.
  scope :for_project, ->(project) {
    project_id = project.respond_to?(:id) ? project.id : project
    where(documentable_type: "Project", documentable_id: project_id)
      .or(where(documentable_type: "ProjectStage", documentable_id: ProjectStage.where(project_id: project_id).select(:id)))
  }

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  pg_search_scope :search_text,
                  associated_against: { file_blob: :filename },
                  using: { tsearch: { prefix: true } }

  def file_name
    file_filename&.to_s
  end

  def uploaded_at
    file_attachment&.created_at || created_at
  end
end
