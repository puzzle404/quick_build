class AddHoursToPersonAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :person_attendances, :hours, :decimal, precision: 6, scale: 2
  end
end
