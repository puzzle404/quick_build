class ProjectPerson < ApplicationRecord
  enum :status, { active: 0, inactive: 1 }

  belongs_to :project
  has_many :person_attendances, dependent: :destroy

  validates :full_name, presence: true

  def current?
    active? && (end_date.nil? || end_date >= Date.current)
  end
end

