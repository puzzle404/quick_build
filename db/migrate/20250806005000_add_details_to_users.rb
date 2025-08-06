# frozen_string_literal: true

class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :address, :string
    add_column :users, :phone, :string
  end
end
