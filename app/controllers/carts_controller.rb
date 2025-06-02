class CartsController < ApplicationController
  include ApplicationHelper

  def index
    @cart_items = cart_items.includes(product: [:image_attachment]).order(:created_at)
    # @pagy, @products = pagy(@products, limit: 5)
    form_cart_items_json
  end

  def destroy
    cart_items.destroy_all
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(:cart, partial: '/carts/cart') }
      format.json { render json: { success: true }, status: :ok }
    end
  end

  private

  def form_cart_items_json
    @cart_items_json = @cart_items.map do |cart_item|
      { id: cart_item.id,
        name: cart_item.product.name,
        image_url: storage_path(cart_item.product.image),
        price: cart_item.product.price.to_i,
        quantity: cart_item.quantity,
        product_path: "/products/#{cart_item.product.id}" }
    end.to_json
  end
end
