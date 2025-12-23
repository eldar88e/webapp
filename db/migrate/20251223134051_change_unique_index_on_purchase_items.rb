class ChangeUniqueIndexOnPurchaseItems < ActiveRecord::Migration[8.1]
  def change
    remove_index :purchase_items, name: :index_purchase_items_on_purchase_id_and_product_id
    add_index :purchase_items,
              [:purchase_id, :product_id, :unit_cost],
              unique: true,
              name: :index_purchase_items_unique_by_price
  end
end
