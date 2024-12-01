class CartItemsController < ApplicationController
  before_action :set_cart_item, only: %i[ update destroy ]

  # POST /order_items or /order_items.json
  def create
    cart      = current_user.cart
    cart_item = cart.cart_items.find_or_initialize_by(product_id: cart_item_params[:product_id])

    cart_item.quantity += 1 if cart_item.persisted?
    return render turbo_stream: success_notice('Товар добавлен в корзину.') if cart_item.save

    render turbo_stream: error_notice('Не удалось добавить товар в корзину.')
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
