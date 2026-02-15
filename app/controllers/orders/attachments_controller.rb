module Orders
  class AttachmentsController < ApplicationController
    before_action :set_order
    before_action :check_order_status, only: :create

    def new; end

    def create
      @order.attachment.attach(params[:order][:attachment])
      result = Payment::ApiService.order_check_down(@order.payment_transaction, helpers.storage_path(@order.attachment))

      if result&.dig('response') == 'success'
        redirect_to orders_path, notice: t('.success')
      else
        @order.attachment.purge
        msg    = "‼️ Failed to attach check for Order ##{@order.id}.\nResponse:\n#{result}"
        markup = { markup_url: 'admin/orders', markup_text: '📋 Перейти к заказам' }
        TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids), **markup)
        redirect_to orders_path, alert: t('.error')
      end
    end


    private

    def set_order
      @order = Order.find(params[:order_id])
    end

    def check_order_status
      redirect_to orders_path, alert: t('.already_attached') if @order.status != 'paid' || @order.attachment.attached?
    end
  end
end
