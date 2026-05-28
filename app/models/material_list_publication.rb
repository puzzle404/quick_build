class MaterialListPublication < ApplicationRecord
  enum :visibility, { private: 0, public: 1 }, prefix: true

  belongs_to :material_list

  validates :material_list, presence: true

  def publish!
    update!(visibility: :public, published_at: Time.current, unpublished_at: nil)
  end

  def unpublish!
    update!(visibility: :private, unpublished_at: Time.current)
  end
end
