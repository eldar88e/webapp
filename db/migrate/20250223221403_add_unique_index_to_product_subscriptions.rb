class AddUniqueIndexToProductSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :product_subscriptions, [:user_id, :product_id], unique: true
  end
end
