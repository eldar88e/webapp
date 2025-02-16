class ChangeTotalAmountInOrders < ActiveRecord::Migration[7.2]
  def change
    change_column_default :orders, :total_amount, 0
    change_column_null :orders, :total_amount, false, 0
  end
end
