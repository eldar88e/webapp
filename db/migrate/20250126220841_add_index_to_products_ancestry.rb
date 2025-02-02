class AddIndexToProductsAncestry < ActiveRecord::Migration[7.2]
  def change
    add_index :products, :ancestry
  end
end
