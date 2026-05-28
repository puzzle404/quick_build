class PersonAttendance < ApplicationRecord
  belongs_to :project_person

  validates :occurred_at, presence: true

  def coordinates?
    latitude.present? && longitude.present?
  end
end

