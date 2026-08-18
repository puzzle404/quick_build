class Document < ApplicationRecord
  include PgSearch::Model
  belongs_to :documentable, polymorphic: true

  has_one_attached :file
  has_one :file_blob, through: :file_attachment, source: :blob

  validates :file, presence: true

  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true

  pg_search_scope :search_text,
                  associated_against: { file_blob: :filename },
                  using: { tsearch: { prefix: true } }

  def file_name
    file_filename&.to_s
  end

  def uploaded_at
    file_attachment&.created_at || created_at
  end
end
