class AddRedesignFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :client, :string
    add_column :projects, :budget_cents, :bigint
    add_column :projects, :progress_curve, :jsonb
    add_column :projects, :progress_plan, :jsonb
  end
end
