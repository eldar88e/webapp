class RenameTierNameToTitleInAccountTiers < ActiveRecord::Migration[7.2]
  def change
    rename_column :account_tiers, :tier_name, :title
  end
end
