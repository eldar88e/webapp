class AddDataToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :data, :jsonb
  end
end
