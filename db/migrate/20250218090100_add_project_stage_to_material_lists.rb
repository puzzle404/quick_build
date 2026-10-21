class AddProjectStageToMaterialLists < ActiveRecord::Migration[8.0]
  def change
    add_reference :material_lists, :project_stage, foreign_key: true

    add_index :material_lists, %i[project_id project_stage_id]
  end
end
