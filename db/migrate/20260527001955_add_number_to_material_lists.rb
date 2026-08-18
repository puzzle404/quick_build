class AddNumberToMaterialLists < ActiveRecord::Migration[8.0]
  def change
    add_column :material_lists, :number, :integer
    add_index  :material_lists, [ :project_id, :number ], unique: true
  end
end
