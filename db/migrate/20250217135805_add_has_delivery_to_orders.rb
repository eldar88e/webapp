class AddHasDeliveryToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :has_delivery, :boolean, default: false, null: false
  end
end
