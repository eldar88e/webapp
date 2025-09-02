class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :product, counter_cache: :favorites_count

  validates :user_id, uniqueness: { scope: :product_id }
end
