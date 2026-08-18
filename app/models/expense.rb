class Expense < ApplicationRecord
  belongs_to :project
  belongs_to :project_stage, optional: true
  belongs_to :author, class_name: "User"
  # Un gasto puede originarse al marcar una lista de materiales como pagada.
  # El vínculo es el único estado de "pagada": no hay paid_at que se desincronice.
  belongs_to :material_list, optional: true

  has_one_attached :receipt

  enum :category, { labor: 0, materials_misc: 1, rentals: 2, other: 3 }

  ALLOWED_RECEIPT_TYPES = %w[image/jpeg image/png application/pdf].freeze

  # Canonical (label, value) pairs for the category <select> on the expense
  # forms. Moved here from the project's old inline expense modal component
  # (deleted in the drawer migration) so it survives that deletion. Keep
  # labels in sync with
  # Constructors::Projects::ExpensesListComponent::CATEGORY_LABELS, which maps
  # the same categories value => label for read-only display.
  CATEGORY_OPTIONS = [
    [ "Mano de obra", "labor" ],
    [ "Materiales sueltos", "materials_misc" ],
    [ "Alquileres", "rentals" ],
    [ "Otros", "other" ]
  ].freeze

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :incurred_on, presence: true
  validate :stage_belongs_to_same_project
  validate :material_list_belongs_to_same_project
  validate :acceptable_receipt_type

  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_stage,   ->(stage_id)   { where(project_stage_id: stage_id) }
  scope :recent_first, -> { order(incurred_on: :desc, id: :desc) }
  scope :from_material_lists, -> { where.not(material_list_id: nil) }

  def amount
    amount_cents / 100.0
  end

  private

  def stage_belongs_to_same_project
    return if project_stage_id.blank?
    return if project_stage&.project_id == project_id

    errors.add(:project_stage, "debe pertenecer al mismo proyecto")
  end

  def material_list_belongs_to_same_project
    return if material_list_id.blank?
    return if material_list&.project_id == project_id

    errors.add(:material_list, "debe pertenecer al mismo proyecto")
  end

  def acceptable_receipt_type
    return unless receipt.attached?
    return if ALLOWED_RECEIPT_TYPES.include?(receipt.content_type)

    errors.add(:receipt, "debe ser JPG, PNG o PDF")
  end
end
