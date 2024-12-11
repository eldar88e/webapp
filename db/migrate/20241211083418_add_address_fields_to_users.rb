class AddAddressFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :street, :string
    add_column :users, :home, :string
    add_column :users, :apartment, :string
    add_column :users, :build, :string
  end
end
