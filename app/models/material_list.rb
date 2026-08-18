class MaterialList < ApplicationRecord
  include PgSearch::Model
  enum :status, { draft: 0, ready_for_review: 1, approved: 2 }
  enum :source_type, { manual: 0, pdf_upload: 1, excel_upload: 2 }

  belongs_to :project
  belongs_to :author, class_name: "User"
  belongs_to :project_stage, optional: true

  has_many :material_items, dependent: :destroy, inverse_of: :material_list
  # Gastos generados al marcar la lista como pagada. Nullify (no destroy):
  # borrar la lista no debe borrar plata ya registrada en la obra.
  has_many :expenses, dependent: :nullify
  has_one :material_list_publication, dependent: :destroy

  has_one_attached :source_file

  validates :name, presence: true
  validates :number, uniqueness: { scope: :project_id }, allow_nil: true, on: :create
  validate :stage_belongs_to_project

  before_create :assign_next_number
  before_save :sync_approved_timestamp

  pg_search_scope :search_text,
                  against: [ :name, :notes ],
                  associated_against: { project_stage: [ :name, :description ] },
                  using: { tsearch: { prefix: true } }

  def display_number
    number.present? ? "##{number}" : ""
  end

  # "Pagada" se deriva de tener gastos asociados: borrar el gasto la
  # desmarca sola, sin columna denormalizada que se desincronice.
  def paid?
    expenses.any?
  end

  def paid_cents
    expenses.sum(:amount_cents)
  end

  # Total estimado de la lista (cantidad × costo unitario, en centavos).
  # Es el monto que se propone al marcarla como pagada.
  def estimated_total_cents
    material_items.sum { |item| item.total_estimated_cost_cents.to_i }
  end

  private

  def assign_next_number
    return if number.present?

    # advisory lock por proyecto: serializa la asignación de número entre
    # creaciones concurrentes. Se libera al commitear la transacción del save.
    self.class.connection.execute(
      ActiveRecord::Base.sanitize_sql([ "SELECT pg_advisory_xact_lock(?)", project_id ])
    )

    self.number = MaterialList.where(project_id: project_id).maximum(:number).to_i + 1
  end

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
