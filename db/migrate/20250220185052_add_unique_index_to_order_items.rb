class AddUniqueIndexToOrderItems < ActiveRecord::Migration[7.2]
  def change
    add_index :order_items, [:order_id, :product_id], unique: true

    change_column :order_items, :quantity, :integer, null: false, default: 1
  end
end
