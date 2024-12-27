class AddIsIncomingToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :is_incoming, :boolean, default: true, null: false
  end
end
