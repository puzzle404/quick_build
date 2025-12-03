class Material < ApplicationRecord
  has_many :construction_item_materials
  has_many :construction_items, through: :construction_item_materials

  validates :name, presence: true
  validates :unit, presence: true
end
