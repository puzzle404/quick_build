class CreateImages < ActiveRecord::Migration[7.1]
  def change
    create_table :images do |t|
      t.references :imageable, polymorphic: true, null: false
      t.string :title
      t.text :description
      t.timestamps
    end
  end
end

