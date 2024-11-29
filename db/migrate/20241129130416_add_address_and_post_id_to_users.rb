class AddAddressAndPostIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :address, :string
    add_column :users, :postal_code, :integer
  end
end
