class AddUniqueIndexToPurchaseItems < ActiveRecord::Migration[7.2]
  def change
    add_index :purchase_items, [:purchase_id, :product_id], unique: true
  end
end
