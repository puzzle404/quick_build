class Product < ApplicationRecord
  include PgSearch::Model

  acts_as_tenant(:company)
  belongs_to :company
  belongs_to :category
  has_many_attached :images

  has_many :line_items, dependent: :destroy
  
  pg_search_scope :search_by_name, against: :name, using: { tsearch: { prefix: true } }

  validates :name, :price_cents, presence: true
end
