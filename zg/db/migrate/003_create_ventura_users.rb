class CreateVenturaUsers < ActiveRecord::Migration
  def change
    create_table :ventura_users do |t|
      t.integer :user_id
      t.string :git_login
      t.integer :git_login_id
      t.integer :oauth_id
      t.string :oauth_token
    end

    add_index :ventura_users, :git_login
    add_index :ventura_users, :git_login_id
  end
end
