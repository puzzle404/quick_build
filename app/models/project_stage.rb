class ProjectStage < ApplicationRecord
  include PgSearch::Model

  belongs_to :project
  belongs_to :parent, class_name: "ProjectStage", optional: true

  has_many :sub_stages, class_name: "ProjectStage", foreign_key: :parent_id, dependent: :destroy
  has_many :material_lists, dependent: :nullify
  has_many :images, as: :imageable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy

  before_validation :assign_position, on: :create

  validates :name, presence: true
  validate :ensure_end_date_is_after_start_date
  validate :parent_belongs_to_same_project
  validate :parent_must_be_root

  scope :root, -> { where(parent_id: nil) }
  scope :children, -> { where.not(parent_id: nil) }
  scope :ordered, lambda {
    order(:position, Arel.sql("CASE WHEN start_date IS NULL THEN 1 ELSE 0 END"), :start_date, :created_at)
  }

  pg_search_scope :search_main_scope,
                  against: [ :name, :description, :start_date, :end_date ],
                  associated_against: { sub_stages: [ :name, :description, :start_date, :end_date ] },
                  using: { tsearch: { prefix: true } }

  pg_search_scope :search_sub_scope,
                  against: [ :name, :description, :start_date, :end_date ],
                  using: { tsearch: { prefix: true } }

  def parent?
    parent_id.present?
  end

  private

  def ensure_end_date_is_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "debe ser posterior o igual a la fecha de inicio")
  end

  def parent_belongs_to_same_project
    return if parent.blank?
    return if parent.project_id == project_id

    errors.add(:parent_id, "debe pertenecer al mismo proyecto")
  end

  def assign_position
    return if position.present?
    siblings = project.project_stages.where(parent_id: parent_id)
    self.position = siblings.maximum(:position).to_i + 1
  end

  def parent_must_be_root
    return if parent.blank?
    return if parent.parent_id.blank?

    errors.add(:parent_id, "no puede tener más de un nivel de profundidad")
  end
end
