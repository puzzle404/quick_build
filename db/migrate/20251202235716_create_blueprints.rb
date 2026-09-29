class CreateBlueprints < ActiveRecord::Migration[8.0]
  def change
    create_table :blueprints do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :scale_ratio, precision: 10, scale: 6
      t.jsonb :measurements, default: {}, null: false

      t.timestamps
    end
    
    add_index :blueprints, :measurements, using: :gin
  end
end
