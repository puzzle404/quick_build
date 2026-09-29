class AddHourlyRateToProjectPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :project_people, :hourly_rate_cents, :integer
  end
end
