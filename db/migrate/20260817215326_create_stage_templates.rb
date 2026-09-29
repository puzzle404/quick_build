class CreateStageTemplates < ActiveRecord::Migration[8.0]
  # Plantillas de etapas reutilizables entre obras.
  #
  # Los ítems guardan OFFSETS RELATIVOS (start_offset_days + duration_days) y
  # nunca fechas absolutas: copiar las fechas de una obra a otra produciría
  # cronogramas en el pasado. Al aplicar la plantilla, las fechas se calculan
  # desde la fecha de inicio de la obra destino.
  def change
    create_table :stage_templates do |t|
      # NULL sólo para la plantilla base del sistema (builtin).
      t.references :owner, null: true, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      # Trazabilidad de la obra desde la que se guardó; si se borra, la
      # plantilla sobrevive sin origen.
      t.references :source_project, null: true, foreign_key: { to_table: :projects }
      t.integer :visibility, null: false, default: 0
      t.boolean :builtin, null: false, default: false

      t.timestamps
    end

    add_index :stage_templates, [ :owner_id, :name ], unique: true, where: "owner_id IS NOT NULL"

    create_table :stage_template_items do |t|
      t.references :stage_template, null: false, foreign_key: true
      # Un solo nivel de anidamiento, igual que ProjectStage.
      t.references :parent, null: true, foreign_key: { to_table: :stage_template_items }
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.integer :start_offset_days
      t.integer :duration_days
      t.bigint :budget_cents
      t.decimal :budget_pct, precision: 5, scale: 2

      t.timestamps
    end

    add_index :stage_template_items, [ :stage_template_id, :parent_id, :position ],
              name: "index_stage_template_items_on_template_parent_position"
  end
end
