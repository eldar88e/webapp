class CartsController < ApplicationController
  layout "cart", only: [ :index ]
  before_action :set_cart

  def index
    @cart_items = current_user.cart.cart_items.includes(:product).order(:created_at)
    @products   = Product.includes(:image_attachment)
  end

  def show
    @cart_items = @cart.cart_items.includes(:product)
    if @cart_items.present?
      render turbo_stream: [
        turbo_stream.update(:modal, partial: "/carts/cart"),
        turbo_stream.append(:modal, "<script>openModal();</script>".html_safe)
      ]
    else
      render turbo_stream: success_notice('Ваша корзина пуста!')
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cart
      @cart = current_user.cart
    end

    # Only allow a list of trusted parameters through.
    def cart_params
      params.require(:cart).permit(:user_id, :status)
    end
end
