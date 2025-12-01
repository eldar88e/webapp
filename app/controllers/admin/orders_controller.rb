module Admin
  class OrdersController < Admin::ApplicationController
    before_action :set_order, only: %i[edit update destroy]
    before_action :assign_bank_card, only: :update

    def index
      @q_orders       = Order.includes(:user).ransack(params[:q])
      @q_orders.sorts = 'created_at desc' if params[:q].nil?
      @pagy, @orders  = pagy(@q_orders.result)
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, "Редактировать заказ №#{@order.id}"),
        turbo_stream.update(:modal_body, partial: '/admin/orders/edit'),
        turbo_stream.update(:modal_price, "Итого: #{@order.total_amount.round}\u00A0₽")
      ]
    end

    def update
      if @order.update(order_params)
        render turbo_stream: [
          success_notice('Заказ был успешно обновлен.'),
          turbo_stream.replace(@order, partial: '/admin/orders/order', locals: { order: @order })
        ]
      else
        error_notice(@order.errors.full_messages)
      end
    end

    def destroy
      @order.destroy!
      redirect_to admin_orders_path, status: :see_other, notice: t('controller.orders.destroy')
    end

    private

    def assign_bank_card
      @order.bank_card = BankCard.find(params[:order][:bank_card]) if params[:order][:bank_card].present?
    end

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.expect(order: %i[status tracking_number])
    end
  end
end
