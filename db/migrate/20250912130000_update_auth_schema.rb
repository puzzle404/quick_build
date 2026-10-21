class UpdateAuthSchema < ActiveRecord::Migration[8.0]
  def change
    # Users: remove Devise columns and add password_digest (simple, non-guarded)
    remove_column :users, :encrypted_password, :string, default: "", null: false
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
    add_column :users, :password_digest, :string, null: false

    # Sessions table
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :user_agent
      t.string :ip_address
      t.timestamps null: false
    end
  end
end
