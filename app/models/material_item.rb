require "bigdecimal"
require "bigdecimal/util"

class MaterialItem < ApplicationRecord
  belongs_to :material_list, inverse_of: :material_items

  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true

  # Los forms cargan el precio en pesos es-AR ("1.500,50", Qb::MoneyFieldComponent);
  # la columna guarda centavos. Vacío borra el precio.
  def estimated_cost_pesos
    nil
  end

  def estimated_cost_pesos=(value)
    self.estimated_cost_cents = value.present? ? Money::ArsParser.to_cents(value) : nil
  end

  def estimated_cost
    return unless estimated_cost_cents

    estimated_cost_cents / 100.0
  end

  def total_estimated_cost_cents
    return unless estimated_cost_cents

    (quantity.to_d * estimated_cost_cents).to_i
  end
end
