class AddRedesignFieldsToProjectStages < ActiveRecord::Migration[8.0]
  def change
    add_column :project_stages, :progress, :integer
    add_column :project_stages, :lead, :string
    add_column :project_stages, :budget_cents, :bigint
    add_column :project_stages, :spent_cents, :bigint
  end
end
