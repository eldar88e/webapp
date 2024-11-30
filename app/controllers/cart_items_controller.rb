class CartItemsController < ApplicationController
  before_action :set_cart_item, only: %i[ update destroy ]

  # POST /order_items or /order_items.json
  def create
    cart      = current_user.cart
    cart_item = cart.cart_items.find_by(product_id: cart_item_params[:product_id])

    if cart_item
      cart_item.quantity += 1
      if cart_item.save
        success_notice('Количество товара в корзине обновлено.')
      else
        error_notice('Не удалось обновить количество товара.')
      end
    else
      cart_item = cart.cart_items.new(cart_item_params)
      if cart_item.save
        success_notice('Товар добавлен в корзину.')
      else
        error_notice('Не удалось добавить товар в корзину.')
      end
    end
    redirect_to root_path
  end

  # PATCH/PUT /order_items/1 or /order_items/1.json
  def update

  end

  # DELETE /order_items/1 or /order_items/1.json
  def destroy
    @order_item.destroy!

    respond_to do |format|
      format.html { redirect_to order_items_path, status: :see_other, notice: "Order item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cart_item
      @cart_item = current_user.cart.cart_items.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cart_item_params
      params.require(:cart_item).permit(:product_id, :quantity)
    end
end
