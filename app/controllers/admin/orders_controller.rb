module Admin
  class OrdersController < Admin::ApplicationController
    before_action :set_order, only: %i[edit update destroy]
    include Pagy::Backend

    def index
      @pagy, @orders = pagy(Order.includes(:user), items: 20)
    end

    def edit; end

    def update
      if @order.update(order_params)
        redirect_to admin_orders_path, notice: "Order was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @order.destroy!
      redirect_to admin_orders_path, status: :see_other, notice: "Order was successfully destroyed."
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:status)
    end
  end
end
