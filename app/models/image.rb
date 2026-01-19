class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  has_one_attached :file

  validates :file, presence: true

  before_validation :ensure_title

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  def uploaded_at
    file_attachment&.created_at || created_at
  end

  private

  def ensure_title
    self.title = file_filename.to_s if title.blank? && file.present?
  end
end

