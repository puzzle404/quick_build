# frozen_string_literal: true

class AddDetailsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :address, :string
    add_column :companies, :phone, :string
  end
end
