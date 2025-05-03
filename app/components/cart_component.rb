# frozen_string_literal: true

class CartComponent < ViewComponent::Base
  def initialize(cart:)
    @cart        = cart
    @total_price = cart.cart_items.joins(:product).sum('products.price * cart_items.quantity')
  end
end
