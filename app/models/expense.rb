class Expense < ApplicationRecord
  belongs_to :project
  belongs_to :project_stage, optional: true
  belongs_to :author, class_name: "User"

  has_one_attached :receipt

  enum :category, { labor: 0, materials_misc: 1, rentals: 2, other: 3 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :incurred_on, presence: true
  validate :stage_belongs_to_same_project

  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_stage,   ->(stage_id)   { where(project_stage_id: stage_id) }
  scope :recent_first, -> { order(incurred_on: :desc, id: :desc) }

  def amount
    amount_cents / 100.0
  end

  private

  def stage_belongs_to_same_project
    return if project_stage.blank?
    return if project_stage.project_id == project_id

    errors.add(:project_stage, "debe pertenecer al mismo proyecto")
  end
end
