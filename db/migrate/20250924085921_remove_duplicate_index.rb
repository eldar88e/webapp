class RemoveDuplicateIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :cart_items, name: 'index_cart_items_on_cart_id'
    remove_index :reviews, name: 'index_reviews_on_user_id'
  end
end
