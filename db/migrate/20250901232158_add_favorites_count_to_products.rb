class AddFavoritesCountToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :favorites_count, :integer, default: 0, null: false
  end

  def up
    Product.find_each { |product| Product.reset_counters(product.id, :favorites) }
  end
end
