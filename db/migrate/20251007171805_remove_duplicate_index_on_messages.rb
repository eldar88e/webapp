class RemoveDuplicateIndexOnMessages < ActiveRecord::Migration[7.2]
  def change
    remove_index :messages, name: :index_messages_on_tg_id
  end
end
