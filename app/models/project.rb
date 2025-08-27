class Project < ApplicationRecord
  belongs_to :constructor, class_name: 'User'

  enum status: { planned: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true
end
