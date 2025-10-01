class AddTgMsgToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :tg_msg, :boolean, default: true, null: false
  end
end
