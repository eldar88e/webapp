class AddApprovedToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :approved, :boolean, default: false, null: false
  end
end
