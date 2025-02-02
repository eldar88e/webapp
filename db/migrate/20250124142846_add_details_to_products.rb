class AddDetailsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :weight, :string
    add_column :products, :dosage_form, :string
    add_column :products, :package_quantity, :integer
    add_column :products, :main_ingredient, :string
    add_column :products, :made_id, :string
  end
end
