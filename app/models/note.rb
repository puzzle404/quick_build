class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true
  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :body,  length: { maximum: 10_000 }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
