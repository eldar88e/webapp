class AddBonusToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :bonus, :integer, default: 0, null: false
  end
end
