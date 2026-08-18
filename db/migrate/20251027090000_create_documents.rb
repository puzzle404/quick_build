class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.references :documentable, polymorphic: true, null: false
      t.timestamps
    end
  end
end
