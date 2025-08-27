class Project < ApplicationRecord
  enum :status, [ :planned, :in_progress, :completed]
  
  belongs_to :owner, class_name: 'User'
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user

  validates :name, presence: true
end
