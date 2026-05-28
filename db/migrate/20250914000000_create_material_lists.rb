class CreateMaterialLists < ActiveRecord::Migration[7.1]
  def change
    create_table :material_lists do |t|
      t.references :project, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.integer :source_type, null: false, default: 0
      t.text :notes
      t.datetime :approved_at

      t.timestamps
    end

    add_index :material_lists, [:project_id, :status]

    create_table :material_items do |t|
      t.references :material_list, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :quantity, precision: 12, scale: 2, null: false, default: 0
      t.string :unit, null: false, default: "unidad"
      t.integer :estimated_cost_cents
      t.string :confidence_label
      t.text :notes

      t.timestamps
    end

    create_table :material_list_publications do |t|
      t.references :material_list, null: false, foreign_key: true, index: { unique: true }
      t.integer :visibility, null: false, default: 0
      t.datetime :published_at
      t.datetime :unpublished_at

      t.timestamps
    end
  end
end
