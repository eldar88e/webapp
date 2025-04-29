class CartsController < ApplicationController
  # before_action :available_products

  def index
    @cart_items = current_user.cart.cart_items.includes(product: [:image_attachment]).order(:created_at)
    # @pagy, @products = pagy(@products, limit: 5)
  end

  def destroy
    current_user.cart.cart_items.destroy_all
    render turbo_stream: [
      turbo_stream.replace(:cart, partial: '/carts/cart'),
      success_notice('Корзина очищена.')
    ]
  end
end
