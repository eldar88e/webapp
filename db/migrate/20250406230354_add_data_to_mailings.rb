class AddDataToMailings < ActiveRecord::Migration[7.2]
  def change
    add_column :mailings, :data, :jsonb
  end
end
