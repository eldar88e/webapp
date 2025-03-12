class AddUniqueIndexToReviews < ActiveRecord::Migration[7.2]
  def change
    add_index :reviews, [:user_id, :product_id], unique: true
  end
end
