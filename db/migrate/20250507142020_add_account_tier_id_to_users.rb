class AddAccountTierIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :account_tier, foreign_key: { to_table: :account_tiers }, null: true
  end
end
