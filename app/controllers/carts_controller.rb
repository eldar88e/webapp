class CartsController < ApplicationController
  before_action :set_cart, only: %i[ show destroy ]

  # GET /carts/1 or /carts/1.json
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

  # DELETE /carts/1 or /carts/1.json
  def destroy
    @cart.destroy!
    redirect_to root_path, status: :see_other, notice: "Cart was successfully destroyed."
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
