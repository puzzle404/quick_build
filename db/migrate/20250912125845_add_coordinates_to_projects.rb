class AddCoordinatesToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :latitude, :float
    add_column :projects, :longitude, :float
  end
end
