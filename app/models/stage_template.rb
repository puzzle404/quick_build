# Plantilla de etapas reutilizable entre obras.
#
# Los ítems guardan OFFSETS RELATIVOS al inicio de la obra
# (start_offset_days + duration_days), nunca fechas absolutas: copiar las
# fechas de una obra a otra produciría cronogramas en el pasado. Al aplicarla,
# el cronograma se recalcula desde la fecha de inicio de la obra destino.
#
# `owner` es NULL sólo para plantillas del sistema (`builtin`). Todo lo demás
# es privado del constructor que la guardó; `visibility` deja preparada la
# compartición (org / global) sin usarse todavía.
class StageTemplate < ApplicationRecord
  # `private` es palabra reservada de Ruby: el prefijo evita definir
  # `StageTemplate#private?` (mismo criterio que MaterialListPublication).
  enum :visibility, { private: 0, org: 1, global: 2 }, prefix: true

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :source_project, class_name: "Project", optional: true

  has_many :items, -> { order(:position, :id) },
           class_name: "StageTemplateItem", dependent: :destroy, inverse_of: :stage_template
  has_many :root_items, -> { where(parent_id: nil).order(:position, :id) },
           class_name: "StageTemplateItem", inverse_of: :stage_template

  validates :name, presence: true, length: { maximum: 120 }
  validates :name, uniqueness: { scope: :owner_id, case_sensitive: false,
                                 message: "ya lo estás usando en otra plantilla" },
                   if: -> { owner_id.present? }
  validate :owner_present_unless_builtin

  scope :ordered, -> { order(:name) }
  scope :owned_by, ->(user) { where(owner: user) }
  # Lo que un constructor puede aplicar: lo suyo + las plantillas del sistema.
  # Usar SIEMPRE este scope al resolver un stage_template_id que viene por
  # params, o se filtran rubros y presupuestos de otros constructores.
  scope :available_for, ->(user) { where(owner: user).or(where(builtin: true)) }

  # Los contadores y el armado del árbol asumen `includes(:items)` y ordenan
  # en Ruby para no disparar una query por fila del selector.
  def root_items_list
    sorted_items.select { |item| item.parent_id.nil? }
  end

  def sub_items_of(root)
    sorted_items.select { |item| item.parent_id == root.id }
  end

  def root_items_count
    root_items_list.size
  end

  def sub_items_count
    sorted_items.count { |item| item.parent_id.present? }
  end

  private

  def sorted_items
    @sorted_items ||= items.to_a.sort_by { |item| [ item.position.to_i, item.id.to_i ] }
  end

  def owner_present_unless_builtin
    return if builtin?
    return if owner_id.present?

    errors.add(:owner, :blank)
  end
end
