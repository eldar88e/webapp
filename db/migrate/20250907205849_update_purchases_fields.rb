class UpdatePurchasesFields < ActiveRecord::Migration[7.2]
  def change
    remove_column :purchases, :acknowledged_at, :datetime
    remove_column :purchases, :received_at, :datetime
    add_column :purchases, :cancelled_at, :datetime
  end
end
