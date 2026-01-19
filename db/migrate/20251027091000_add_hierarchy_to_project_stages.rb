class AddHierarchyToProjectStages < ActiveRecord::Migration[7.1]
  def up
    add_reference :project_stages, :parent, foreign_key: { to_table: :project_stages }, index: true
    add_column :project_stages, :position, :integer, null: false, default: 0

    reset_stage_class

    populate_positions
  end

  def down
    remove_column :project_stages, :position
    remove_reference :project_stages, :parent, foreign_key: { to_table: :project_stages }
  end

  private

  def reset_stage_class
    @stage_class = Class.new(ApplicationRecord) do
      self.table_name = "project_stages"
    end
    @stage_class.reset_column_information
  end

  def stage_class
    @stage_class || reset_stage_class
  end

  def populate_positions
    stage_class.unscoped.distinct.pluck(:project_id).each do |project_id|
      stages = stage_class.where(project_id:, parent_id: nil).order(:created_at).pluck(:id)
      stages.each_with_index do |stage_id, index|
        stage_class.where(id: stage_id).update_all(position: index)
      end
    end
  end
end
