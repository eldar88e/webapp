class AddTgMsgIdToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :tg_msg_id, :bigint
  end
end
