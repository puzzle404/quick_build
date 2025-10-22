class Project < ApplicationRecord
  enum :status, [ :planned, :in_progress, :completed]
  
  belongs_to :owner, class_name: 'User'
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :material_lists, dependent: :destroy
  has_many_attached :images

  validates :name, presence: true

   # Helper para saber si el proyecto tiene ubicación
  def located?
    latitude.present? && longitude.present?
  end
end
