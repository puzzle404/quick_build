class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  has_one_attached :file

  validates :file, presence: true

  scope :featured, -> { where(featured: true) }

  validate :only_one_featured_per_imageable

  before_validation :ensure_title

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  def uploaded_at
    file_attachment&.created_at || created_at
  end

  private

  def ensure_title
    self.title = file_filename.to_s if title.blank? && file.present?
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
