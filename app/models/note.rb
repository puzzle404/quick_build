class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
