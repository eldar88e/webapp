class AddRawNamesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_name_raw, :string
    add_column :users, :last_name_raw, :string
  end
end
