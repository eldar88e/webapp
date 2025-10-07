class AddIndexOnMessagesTgIdAndCreatedAtDesc < ActiveRecord::Migration[7.2]
  def change
    add_index :messages, [:tg_id, :created_at], order: { created_at: :desc }, name: :index_messages_on_tg_id_created_at_desc
  end
end
