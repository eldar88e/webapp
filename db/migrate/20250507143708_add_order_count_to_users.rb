class AddOrderCountToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :order_count, :integer, default: 0, null: false
  end
end
