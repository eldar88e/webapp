class CartItemsController < ApplicationController
  before_action :set_cart, :set_cart_items
  before_action :set_cart_item, only: :update

  def create
    @cart_item = @cart_items.new(product_id: cart_item_params[:product_id])
    return render_create_success if @cart_item.save

    error_notice(@cart_item.errors.full_messages)
  end

  def update
    # if params[:quantity].to_i.positive? && @cart_item.product.stock_quantity.positive?
    #   return render_updated_item if @cart_item.update(quantity: params[:quantity])
    #
    #   error_notice(@cart_item.errors.full_messages)
    # else
    #   @cart_item.destroy
    #   render_remove_cart_item
    # end

    new_quantity = case
                   when params[:up]
                     @cart_item.quantity + 1
                   when params[:down]
                     @cart_item.quantity - 1
                   else
                     @cart_item.quantity
                   end

    if new_quantity < 1
      @cart_item.destroy
      respond_success
    elsif @cart_item.update(quantity: new_quantity)
      respond_success
    else
      respond_error(@cart_item.errors.full_messages)
    end
  end

  private

  def respond_success
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "cart-btn-#{@cart_item.product.id}", partial: '/products/btn', locals: { product: @cart_item.product }
          ),
          turbo_stream.update('cart-summary', partial: '/carts/cart_summary')
        ]
      end
      format.json do
        render json: {
          success: true,
          cart_item: @cart_item.as_json(only: [:id, :quantity]),
          total_price: current_user.cart.total_price
        }, status: :ok
      end
    end
  end

  def respond_error(errors)
    respond_to do |format|
      format.turbo_stream { error_notice errors }
      format.json { render json: { success: false, errors: errors }, status: :unprocessable_entity }
    end
  end


  def render_create_success
    render turbo_stream: [
      turbo_stream.update('cart-summary', partial: '/carts/cart_summary'),
      turbo_stream.update("cart-btn-#{@cart_item.product.id}", partial: '/products/btn', locals: { product: @cart_item.product })
    ] # + update_item_counters(cart_item_params[:product_id])
  end

  def render_remove_cart_item
    return render_updated_item if @cart_items.size.positive?

    render turbo_stream: [
      turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
      success_notice(t('empty_cart'))
    ] + update_item_counters(@cart_item.product_id)
  end

  def render_updated_item
    render turbo_stream: [
      turbo_stream.replace(:cart_items, partial: '/carts/cart_items')
    ] + update_item_counters(@cart_item.product_id)
  end

  def set_cart
    @cart = current_user.cart
  end

  def set_cart_items
    @cart_items = @cart.cart_items.order(:created_at).includes(:product)
  end

  def set_cart_item
    @cart_item = @cart_items.find(params[:id])
  end

  def cart_item_params
    params.require(:cart_item).permit(:product_id, :quantity)
  end

  def update_item_counters(id)
    partial = '/layouts/partials/cart_item_counter'
    [
      turbo_stream.replace(:cart_logo, partial: '/layouts/partials/cart'),
      turbo_stream.replace("cart_item_#{id}_counter", partial: partial, locals: { id: id })
    ]
  end
end
