class Company < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :stores, dependent: :destroy
end
