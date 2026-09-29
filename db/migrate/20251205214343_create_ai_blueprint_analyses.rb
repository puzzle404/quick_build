class CreateAiBlueprintAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_blueprint_analyses do |t|
      t.references :blueprint, null: false, foreign_key: true
      t.string :status, null: false, default: 'queued'
      t.jsonb :raw_response
      t.jsonb :suggested_measurements
      t.datetime :applied_at
      t.text :error_message

      t.timestamps
    end
    
    add_index :ai_blueprint_analyses, :status
  end
end
