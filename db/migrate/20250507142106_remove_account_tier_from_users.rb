class RemoveAccountTierFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :account_tier, :integer
  end
end
