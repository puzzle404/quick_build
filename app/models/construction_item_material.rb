class ConstructionItemMaterial < ApplicationRecord
  belongs_to :construction_item
  belongs_to :material

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
