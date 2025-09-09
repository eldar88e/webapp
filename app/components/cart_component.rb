# frozen_string_literal: true

class CartComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(cart:)
    super()
    @cart_items  = cart.cart_items
    @total_price = @cart_items.joins(:product).sum('products.price * cart_items.quantity')
  end
end
