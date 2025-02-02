module Admin
  class OrdersController < Admin::ApplicationController
    before_action :set_order, only: %i[edit update destroy]

    def index
      @q_orders = Order.includes(:user).order(created_at: :desc).ransack(params[:q])
      @pagy, @orders = pagy(@q_orders.result, items: 20)
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать заказ'),
        turbo_stream.update(:modal_body, partial: '/admin/orders/edit')
      ]
    end

    def update
      if @order.update(order_params)
        render turbo_stream: [
          success_notice('Заказ был успешно обновлен.'),
          turbo_stream.replace(@order, partial: '/admin/orders/order', locals: { order: @order })
        ]
      else
        error_notice(@order.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @order.destroy!
      redirect_to admin_orders_path, status: :see_other, notice: 'Заказ был успешно удален.'
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:status, :tracking_number)
    end
  end
end
