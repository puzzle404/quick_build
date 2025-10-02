class User < ApplicationRecord
  has_secure_password
  
  enum :role, [ :buyer, :constructor, :admin, :seller ]

  belongs_to :company, optional: true
  has_many :orders, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :company, presence: true, if: :seller?
end
