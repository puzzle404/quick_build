class Product < ApplicationRecord
  acts_as_tenant(:company)
  belongs_to :company
  has_many_attached :images
  
  validates :name, :price_cents, presence: true
end
