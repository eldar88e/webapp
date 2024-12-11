class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  after_commit :add_delivery_item_if_needed, on: [:create, :update, :destroy]

  private

  def add_delivery_item_if_needed
    delivery_id        = Setting.fetch_value(:delivery_id)
    non_delivery_items = cart.cart_items.where.not(product_id: delivery_id)
    if non_delivery_items.count == 1 && non_delivery_items.first.quantity == 1
      cart.cart_items.find_or_create_by(product_id: delivery_id)
    else
      cart.cart_items.find_by(product_id: delivery_id)&.destroy
    end
  end
end
