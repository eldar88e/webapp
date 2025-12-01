class CartItemsController < ApplicationController
  before_action :set_cart_items, only: :create
  before_action :set_cart_item, :set_new_quantity, only: :update

  def create
    @cart_item = @cart_items.new(product_id: cart_item_params[:product_id])
    return render_create_success if @cart_item.save

    error_notice(@cart_item.errors.full_messages)
  end

  def update
    if @cart_item.quantity < 1
      @cart_item.destroy
      respond_success
    elsif @cart_item.save
      respond_success
    else
      respond_error(@cart_item.errors.full_messages)
    end
  end

  private

  def respond_success
    respond_to do |format|
      format.turbo_stream { handle_success_turbo }
      format.json do
        render json: { success: true, cart_item: { id: @cart_item.id, quantity: @cart_item.quantity } }, status: :ok
      end
    end
  end

  def handle_success_turbo
    render turbo_stream: [
      turbo_stream.update(
        "cart-btn-#{@cart_item.product.id}", partial: '/products/btn', locals: { product: @cart_item.product }
      ),
      turbo_stream.update('cart-summary', partial: '/carts/cart_summary')
    ]
  end

  def respond_error(errors)
    respond_to do |format|
      format.turbo_stream { error_notice errors }
      format.json { render json: { success: false, errors: errors }, status: :unprocessable_content }
    end
  end

  def render_create_success
    render turbo_stream: [
      turbo_stream.update(
        "cart-btn-#{@cart_item.product.id}", partial: '/products/btn', locals: { product: @cart_item.product }
      ),
      turbo_stream.update('cart-summary', partial: '/carts/cart_summary')
    ]
  end

  def set_new_quantity
    if params[:up]
      @cart_item.quantity += 1
    elsif params[:down]
      @cart_item.quantity = [@cart_item.quantity - 1, 0].max
    end
  end

  def set_cart_items
    @cart_items = cart_items.order(:created_at).includes(:product)
  end

  def set_cart_item
    @cart_item = cart_items.find(params[:id])
  end

  def cart_item_params
    params.expect(cart_item: %i[product_id quantity])
  end
end
