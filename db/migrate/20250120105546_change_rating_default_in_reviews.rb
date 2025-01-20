class ChangeRatingDefaultInReviews < ActiveRecord::Migration[7.2]
  def change
    change_column_default :reviews, :rating, 0
    change_column_null :reviews, :rating, false
  end
end
