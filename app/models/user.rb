class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :company, optional: true
  has_many :orders, dependent: :destroy

  enum role: { buyer: 0, seller: 1, constructor: 2, admin: 3 }

  validates :company, presence: true, if: :seller?
end
