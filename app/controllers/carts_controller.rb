class CartsController < ApplicationController
  before_action :available_products

  def index
    @cart_items = current_user.cart.cart_items.includes(:product).order(:created_at)
    @pagy, @products = pagy(@products, limit: 5)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(:pagination, partial: '/products/pagination'),
          turbo_stream.append(:products, partial: '/products/products')
        ]
      end
    end
  end
end
