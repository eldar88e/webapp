class RemoveDiscountTotalFromPurchases < ActiveRecord::Migration[7.2]
  def change
    remove_column :purchases, :discount_total, :decimal
  end
end
