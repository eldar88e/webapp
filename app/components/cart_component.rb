# frozen_string_literal: true

class CartComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(cart:)
    super()
    @cart        = cart
    @total_price = cart.cart_items.joins(:product).sum('products.price * cart_items.quantity')
  end
end
