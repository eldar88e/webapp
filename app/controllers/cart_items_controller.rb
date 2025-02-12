class CartItemsController < ApplicationController
  before_action :set_cart_item, only: %i[update]

  def create
    cart      = current_user.cart
    cart_item = cart.cart_items.find_or_initialize_by(product_id: cart_item_params[:product_id])

    cart_item.quantity += 1 if cart_item.persisted?

    if cart_item.save
      @cart_items = current_user.cart.cart_items.order(:created_at).includes(:product)
      render turbo_stream: [
        turbo_stream.update(:cart, partial: '/carts/cart'),
        success_notice('Товар добавлен в корзину.')
      ] + update_counters(cart_item_params[:product_id])
    else
      error_notice(cart_item.errors.full_messages)
    end
  end

  def update
    cart_item = current_user.cart.cart_items.find(params[:id])
    params[:quantity].to_i.positive? ? update_cart_item(cart_item) : remove_cart_item(cart_item)
  end

  private

  def update_cart_item(cart_item)
    if cart_item.update(quantity: params[:quantity])
      render turbo_stream: [
        turbo_stream.replace(
          "cart_item_#{cart_item.id}",
          partial: '/cart_items/cart_item', locals: { cart_item: cart_item }
        )
      ] + update_counters(cart_item.product.id)
    else
      error_notice(cart_item.errors.full_messages)
    end
  end

  def remove_cart_item(cart_item)
    id = cart_item.product.id
    cart_item.destroy
    @cart_items = current_user.cart.cart_items.order(:created_at).includes(:product)
    if @cart_items.where.not(product_id: Setting.fetch_value(:delivery_id)).size.positive?
      return render turbo_stream: [ turbo_stream.remove("cart_item_#{cart_item.id}") ] + update_counters(id)
    end

    render turbo_stream: [
      turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
      success_notice('Ваша корзина пуста!')
    ] + update_counters(id)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_cart_item
    @cart_item = current_user.cart.cart_items.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def cart_item_params
    params.require(:cart_item).permit(:product_id, :quantity)
  end

  def update_counters(id)
    @cart_items ||= current_user.cart.cart_items.order(:created_at).includes(:product)
    [
      turbo_stream.replace(:cart_logo, partial: '/layouts/partials/cart'),
      turbo_stream.replace(
        "cart_item_#{id}_counter",
        partial: '/layouts/partials/cart_item_counter', locals: { id: id }
      ),
      turbo_stream.replace(:cart_items, partial: '/carts/cart_items')
    ]
  end
end
