class RemoveDuplicateIndexes < ActiveRecord::Migration[7.2]
  def change
    remove_index :favorites, name: "index_favorites_on_user_id"
    remove_index :order_items, name: "index_order_items_on_order_id"
    remove_index :product_subscriptions, name: "index_product_subscriptions_on_user_id"
    remove_index :purchase_items, name: "index_purchase_items_on_purchase_id"
  end
end
