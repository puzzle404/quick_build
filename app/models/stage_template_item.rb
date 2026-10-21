# Ítem de una plantilla de etapas. Espeja ProjectStage con dos diferencias:
# las fechas son offsets relativos al inicio de la obra y nunca guarda
# progreso ni gasto (una plantilla es un plan, no un estado).
#
# Convención de duración: `duration_days` es el delta crudo
# `end_date - start_date`, así que una etapa de un solo día vale 0. Al aplicar,
# `end_date = start_date + duration_days` — el ida y vuelta es exacto.
class StageTemplateItem < ApplicationRecord
  belongs_to :stage_template
  belongs_to :parent, class_name: "StageTemplateItem", optional: true

  has_many :children, class_name: "StageTemplateItem", foreign_key: :parent_id,
           dependent: :destroy, inverse_of: :parent

  validates :name, presence: true
  validates :start_offset_days, numericality: { only_integer: true }, allow_nil: true
  validates :duration_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :budget_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  # 999.99 es el techo de la columna decimal(5,2): más que eso rompe en PG.
  validates :budget_pct, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validate :parent_must_be_root
  validate :parent_belongs_to_same_template

  scope :root, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :id) }

  def root?
    parent_id.nil?
  end

  private

  # Mismo límite que ProjectStage#parent_must_be_root: un solo nivel. Sin esto
  # una plantilla de 3 niveles explotaría recién al aplicarse.
  def parent_must_be_root
    return if parent.blank?
    return if parent.parent_id.blank?

    errors.add(:parent_id, "no puede tener más de un nivel de profundidad")
  end

  def parent_belongs_to_same_template
    return if parent.blank?
    return if parent.stage_template_id == stage_template_id

    errors.add(:parent_id, "debe pertenecer a la misma plantilla")
  end
end
