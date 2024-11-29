class AddTgIdToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :tg_id, :integer
    add_index :users, :tg_id, unique: true
  end
end
