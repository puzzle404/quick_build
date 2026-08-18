class Blueprint < ApplicationRecord
  belongs_to :project
  has_many :ai_blueprint_analyses, dependent: :destroy
  
  has_one_attached :file
  
  validates :name, presence: true
  validates :file, presence: true
  
  # Validar que el archivo sea una imagen
  validate :acceptable_file_type
  
  delegate :filename, :content_type, :byte_size, to: :file, prefix: true, allow_nil: true
  
  def file_name
    file_filename&.to_s
  end
  
  def uploaded_at
    file.attachment&.created_at || created_at
  end
  
  private
  
  def acceptable_file_type
    return unless file.attached?
    
    acceptable_types = ['image/jpeg', 'image/png', 'image/jpg']
    unless acceptable_types.include?(file.content_type)
      errors.add(:file, 'debe ser JPG o PNG')
    end
  end
end
