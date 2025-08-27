class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :company, optional: true
  has_many :orders, dependent: :destroy

  enum :role, [ :buyer, :client, :admin, :seller, :constructor ]
  validates :company, presence: true, if: -> { seller? }
  has_many :projects, foreign_key: :constructor_id, inverse_of: :constructor, dependent: :destroy
end
