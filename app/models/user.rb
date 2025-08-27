class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :company, optional: true
  has_many :orders, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy

  enum :role, [ :buyer, :constructor, :admin, :seller ]
  validates :company, presence: true, if: :seller?
end
