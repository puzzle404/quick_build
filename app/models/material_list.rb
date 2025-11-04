class MaterialList < ApplicationRecord
  include PgSearch::Model
  enum :status, { draft: 0, ready_for_review: 1, approved: 2 }
  enum :source_type, { manual: 0, pdf_upload: 1, excel_upload: 2 }

  belongs_to :project
  belongs_to :author, class_name: "User"
  belongs_to :project_stage, optional: true

  has_many :material_items, dependent: :destroy, inverse_of: :material_list
  has_one :material_list_publication, dependent: :destroy

  has_one_attached :source_file

  validates :name, presence: true
  validate :stage_belongs_to_project

  before_save :sync_approved_timestamp

  pg_search_scope :search_text,
                  against: [:name, :notes],
                  associated_against: { project_stage: [:name, :description] },
                  using: { tsearch: { prefix: true } }

  private

  def stage_belongs_to_project
    return if project_stage.blank?
    return if project_stage.project_id == project_id

    errors.add(:project_stage, "no pertenece a esta obra")
  end

  def sync_approved_timestamp
    if approved? && approved_at.blank?
      self.approved_at = Time.current
    elsif !approved? && approved_at.present?
      self.approved_at = nil
    end
  end
end
