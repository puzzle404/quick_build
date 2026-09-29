class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :project, null: false, foreign_key: true
      t.references :project_stage, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "ARS"
      t.integer :category, null: false, default: 0
      t.date :incurred_on, null: false
      t.string :description
      t.timestamps
    end

    add_index :expenses, [ :project_id, :incurred_on ]
    add_index :expenses, [ :project_stage_id, :incurred_on ]
  end
end
