class RenameMadeIdToBrandInProducts < ActiveRecord::Migration[7.2]
  def change
    rename_column :products, :made_id, :brand
  end
end
