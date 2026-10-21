class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  has_one_attached :file

  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  validates :file, presence: true

  scope :featured, -> { where(featured: true) }

  # Fotos de la obra y de todas sus etapas: la galería de la obra muestra las dos.
  scope :for_project, ->(project) {
    project_id = project.respond_to?(:id) ? project.id : project
    where(imageable_type: "Project", imageable_id: project_id)
      .or(where(imageable_type: "ProjectStage", imageable_id: ProjectStage.where(project_id: project_id).select(:id)))
  }

  validate :only_one_featured_per_imageable
  validate :acceptable_image_type

  before_validation :ensure_title

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  def uploaded_at
    file_attachment&.created_at || created_at
  end

  private

  def ensure_title
    self.title = file_filename.to_s if title.blank? && file.present?
  end

  def acceptable_image_type
    return unless file.attached?
    return if ALLOWED_IMAGE_TYPES.include?(file.content_type)

    errors.add(:file, "debe ser una imagen JPG, PNG, WEBP o GIF")
  end

  def only_one_featured_per_imageable
    return unless featured?

    exists = self.class
                 .where(imageable_type: imageable_type, imageable_id: imageable_id, featured: true)
                 .where.not(id: id)
                 .exists?

    errors.add(:featured, "ya hay una imagen destacada para este recurso") if exists
  end
end
