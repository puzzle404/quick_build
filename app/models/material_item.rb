require "bigdecimal"
require "bigdecimal/util"

class MaterialItem < ApplicationRecord
  belongs_to :material_list, inverse_of: :material_items

  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true

  def estimated_cost
    return unless estimated_cost_cents

    estimated_cost_cents / 100.0
  end

  def total_estimated_cost_cents
    return unless estimated_cost_cents

    (quantity.to_d * estimated_cost_cents).to_i
  end
end
