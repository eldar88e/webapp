class AddStartedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :started, :boolean, default: false
  end
end
