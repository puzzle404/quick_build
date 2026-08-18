class CreateProjectPeople < ActiveRecord::Migration[8.0]
  def change
    create_table :project_people do |t|
      t.references :project, null: false, foreign_key: true
      t.string :full_name, null: false
      t.string :document_id
      t.string :phone
      t.string :role_title
      t.integer :status, null: false, default: 0
      t.date :start_date
      t.date :end_date
      t.text :notes

      t.timestamps
    end

    add_index :project_people, [:project_id, :status]
    add_index :project_people, [:project_id, :full_name]
  end
end

