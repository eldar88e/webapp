class AddBonusAndAccountTierToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bonus_balance, :integer, default: 0, null: false
    add_column :users, :account_tier, :integer, default: 0, null: false
  end
end
