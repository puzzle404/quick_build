class Project < ApplicationRecord
  belongs_to :constructor, class_name: 'User'

  enum :status, [ :planned, :in_progress, :completed]

  validates :name, presence: true
end
