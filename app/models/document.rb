class Document < ApplicationRecord
  belongs_to :documentable, polymorphic: true

  has_one_attached :file

  validates :file, presence: true

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  def file_name
    file_filename&.to_s
  end

  def uploaded_at
    file_attachment&.created_at || created_at
  end
end
