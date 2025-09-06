class AddExchangeRateToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :exchange_rate, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
