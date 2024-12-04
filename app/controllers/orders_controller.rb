class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show update ]

  # GET /orders or /orders.json
  def index
    @orders = Order.all
  end

  # GET /orders/1 or /orders/1.json
  def show
    @order_items = @order.order_items
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # POST /orders or /orders.json
  def create
    if params[:page].to_i == 1
      return render turbo_stream: [
        turbo_stream.update(:modal, partial: 'orders/user'),
        turbo_stream.append(:modal, "<script>history.pushState(null, null, '/');</script>".html_safe)
      ]
    end

    cart  = current_user.cart
    order = current_user.orders.find_or_create_by(status: :unpaid)
    order.update!(total_amount: calculate_total_price(cart))

    cart.cart_items.each do |cart_item|
      order_item = order.order_items.find_or_create_by(product: cart_item.product)
      order_item.update(quantity: cart_item.quantity, price: cart_item.product.price)
    end

    # redirect_to order_path(order), notice: "Ваш заказ успешно оформлен!"

    render turbo_stream: [
      success_notice("Ваш заказ успешно оформлен!"),
      turbo_stream.append(:modal, "<script>miniappClose();</script>".html_safe)
    ]
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def calculate_total_price(cart)
      cart.cart_items.sum { |item| item.product.price * item.quantity }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:user_id, :total_amount, :status)
    end
end
