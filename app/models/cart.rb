class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy

  def cart_items_with_product
    cart_items.includes(:product)
  end
end
