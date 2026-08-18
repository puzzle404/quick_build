class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :noteable, polymorphic: true, null: false, index: false
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.text :body, null: false
      t.timestamps
    end

    add_index :notes,
              [ :noteable_type, :noteable_id, :created_at ],
              name: "idx_notes_on_noteable_and_created"
  end
end
