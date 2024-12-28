class AddIsBlockedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_blocked, :boolean, default: false, null: false
  end
end
