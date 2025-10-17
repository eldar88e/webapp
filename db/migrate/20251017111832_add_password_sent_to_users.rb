class AddPasswordSentToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_sent, :boolean, default: false, null: false
  end
end
