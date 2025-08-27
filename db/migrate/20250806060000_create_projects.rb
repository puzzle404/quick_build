class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :location
      t.date :start_date
      t.date :end_date
      t.integer :status, default: 0, null: false
      t.references :constructor, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :projects, :status
    add_index :projects, :start_date
  end
end
