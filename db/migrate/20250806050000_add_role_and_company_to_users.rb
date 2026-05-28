# frozen_string_literal: true

class AddRoleAndCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_reference :users, :company, foreign_key: true
  end
end
