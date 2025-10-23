class ProjectStage < ApplicationRecord
  belongs_to :project

  has_many :material_lists, dependent: :nullify

  validates :name, presence: true
  validate :ensure_end_date_is_after_start_date

  scope :ordered, lambda {
    order(
      Arel.sql("CASE WHEN start_date IS NULL THEN 1 ELSE 0 END"),
      :start_date,
      :created_at
    )
  }

  private

  def ensure_end_date_is_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "debe ser posterior o igual a la fecha de inicio")
  end
end
