class AddDeliveryPriceColumnToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :delivery_price, :integer, default: 0, null: false
  end
end
