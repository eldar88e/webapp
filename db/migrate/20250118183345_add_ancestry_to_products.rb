class AddAncestryToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :ancestry, :string
  end
end
