class ProjectMembership < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :project_id }
end
