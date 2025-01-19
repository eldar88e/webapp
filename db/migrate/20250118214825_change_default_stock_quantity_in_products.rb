class ChangeDefaultStockQuantityInProducts < ActiveRecord::Migration[7.2]
  def change
    change_column_default :products, :stock_quantity, 0
    change_column_null :products, :stock_quantity, false
  end
end
