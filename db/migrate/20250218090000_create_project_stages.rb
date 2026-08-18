class CreateProjectStages < ActiveRecord::Migration[8.0]
  def change
    create_table :project_stages do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_index :project_stages, %i[project_id start_date]
  end
end
