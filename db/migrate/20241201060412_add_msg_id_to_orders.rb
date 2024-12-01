class AddMsgIdToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :msg_id, :integer
  end
end
