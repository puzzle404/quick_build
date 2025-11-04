class ProjectPerson < ApplicationRecord
  include PgSearch::Model
  enum :status, { active: 0, inactive: 1 }

  belongs_to :project
  has_many :person_attendances, dependent: :destroy

  validates :full_name, presence: true

  pg_search_scope :search_text,
                  against: [:full_name, :role_title, :document_id, :notes],
                  using: { tsearch: { prefix: true } }

  def current?
    active? && (end_date.nil? || end_date >= Date.current)
  end
end
