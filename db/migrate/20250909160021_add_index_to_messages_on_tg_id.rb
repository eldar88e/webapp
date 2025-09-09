class AddIndexToMessagesOnTgId < ActiveRecord::Migration[7.2]
  def change
    add_index :messages, :tg_id
  end
end
