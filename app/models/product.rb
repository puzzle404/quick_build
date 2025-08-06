class Product < ApplicationRecord
  acts_as_tenant(:company)
  belongs_to :company
  has_many_attached :images

  has_many :line_items, dependent: :destroy
  
  validates :name, :price_cents, presence: true
end
