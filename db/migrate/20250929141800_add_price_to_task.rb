class AddPriceToTask < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :price, :integer
  end
end
