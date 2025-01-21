class CartsController < ApplicationController
  before_action :available_products

  def index
    @cart_items = current_user.cart.cart_items.includes(:product).order(:created_at)
    respond_to do |format|
      format.turbo_stream do
        if @cart_items.present?
          render turbo_stream: turbo_stream.update(:modal, partial: '/carts/cart')
        else
          render turbo_stream: [
            turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
            success_notice('Ваша корзина пуста!')
          ]
        end
      end
      format.html { render :index }
    end
  end
end
