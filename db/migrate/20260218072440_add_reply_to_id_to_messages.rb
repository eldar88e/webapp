class AddReplyToIdToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :reply_to_id, :bigint
    add_index :messages, :reply_to_id
    add_foreign_key :messages, :messages, column: :reply_to_id, on_delete: :nullify
    add_column :messages, :manager_id, :bigint
    add_index :messages, :manager_id
    add_foreign_key :messages, :users, column: :manager_id, on_delete: :nullify
  end
end
