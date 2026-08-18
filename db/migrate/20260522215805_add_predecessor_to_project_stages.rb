class AddPredecessorToProjectStages < ActiveRecord::Migration[8.0]
  def change
    add_reference :project_stages,
                  :predecessor,
                  foreign_key: { to_table: :project_stages },
                  null: true
  end
end
