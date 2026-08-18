class CreatePersonAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :person_attendances do |t|
      t.references :project_person, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.float :latitude
      t.float :longitude
      t.string :source, null: false, default: "manual"
      t.text :notes

      t.timestamps
    end

    add_index :person_attendances, [:project_person_id, :occurred_at]
  end
end

