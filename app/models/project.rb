class Project < ApplicationRecord
  include PgSearch::Model
  enum :status, [ :planned, :in_progress, :completed]
  
  belongs_to :owner, class_name: 'User'
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :project_stages, dependent: :destroy
  has_many :material_lists, dependent: :destroy
  has_many :project_people, dependent: :destroy
  has_many :images, as: :imageable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :blueprints, dependent: :destroy

  attr_accessor :document_files

  validates :name, presence: true

  pg_search_scope :search_text,
                  against: [:name, :location],
                  using: { tsearch: { prefix: true } }

  # Helper para saber si el proyecto tiene ubicación
  def located?
    latitude.present? && longitude.present?
  end
end
