class Product < ApplicationRecord
  acts_as_tenant(:company)
  belongs_to :company
  belongs_to :category
  has_many_attached :images
  
  validates :name, :price_cents, presence: true
end
