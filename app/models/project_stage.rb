class ProjectStage < ApplicationRecord
  include PgSearch::Model

  belongs_to :project
  belongs_to :parent, class_name: "ProjectStage", optional: true
  belongs_to :predecessor, class_name: "ProjectStage", optional: true

  has_many :sub_stages, class_name: "ProjectStage", foreign_key: :parent_id, dependent: :destroy
  has_many :successors, class_name: "ProjectStage", foreign_key: :predecessor_id, dependent: :nullify
  has_many :material_lists, dependent: :nullify
  has_many :expenses, dependent: :nullify
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :images, as: :imageable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy

  before_validation :assign_position, on: :create

  validates :name, presence: true
  validate :ensure_end_date_is_after_start_date
  validate :parent_belongs_to_same_project
  validate :parent_must_be_root
  validate :predecessor_belongs_to_same_project
  validate :predecessor_must_not_be_self
  validate :predecessor_must_not_create_cycle
  validate :start_after_predecessor_end

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

  def predecessor_belongs_to_same_project
    return if predecessor.blank?
    return if predecessor.project_id == project_id

    errors.add(:predecessor, "debe pertenecer al mismo proyecto")
  end

  def predecessor_must_not_be_self
    return if predecessor.blank?
    return unless predecessor.equal?(self) || (persisted? && predecessor_id == id)

    errors.add(:predecessor, "no puede ser ella misma")
  end

  def predecessor_must_not_create_cycle
    return if predecessor.blank?

    visited = Set.new([ id ].compact)
    cursor  = predecessor
    while cursor
      if visited.include?(cursor.id)
        errors.add(:predecessor, "genera un ciclo de dependencias")
        return
      end
      visited << cursor.id
      cursor = cursor.predecessor
    end
  end

  def start_after_predecessor_end
    return if predecessor.blank? || start_date.blank? || predecessor.end_date.blank?
    # Finish-to-Start: la etapa puede arrancar el mismo día que termina la predecesora.
    return if start_date >= predecessor.end_date

    errors.add(:start_date,
               "no puede ser anterior al fin de la etapa predecesora (#{predecessor.end_date})")
  end
end
