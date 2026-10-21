class CreateMaterialsAndConstructionItems < ActiveRecord::Migration[8.0]
  def change
    create_table :materials do |t|
      t.string :name, null: false
      t.string :unit, null: false # un, kg, m3, lts, m
      t.decimal :price, precision: 10, scale: 2
      t.timestamps
    end

    create_table :construction_items do |t|
      t.string :name, null: false
      t.string :unit, null: false # m, m2, un
      t.string :category # Albañilería, Pintura, Instalaciones
      t.timestamps
    end

    create_table :construction_item_materials do |t|
      t.references :construction_item, null: false, foreign_key: true
      t.references :material, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 4 # Cantidad de material por unidad de item
      t.decimal :waste_factor, default: 1.0 # Factor de desperdicio (ej: 1.10 = 10%)
      t.timestamps
    end
  end
end
