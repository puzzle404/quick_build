class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true
  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :body,  length: { maximum: 10_000 }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # Notas de la obra y de todas sus etapas: la Bitácora muestra las dos.
  scope :for_project, ->(project) {
    project_id = project.respond_to?(:id) ? project.id : project
    where(noteable_type: "Project", noteable_id: project_id)
      .or(where(noteable_type: "ProjectStage", noteable_id: ProjectStage.where(project_id: project_id).select(:id)))
  }
end
