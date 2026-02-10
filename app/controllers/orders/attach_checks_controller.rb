module Orders
  class AttachChecksController < ApplicationController
    before_action :set_order

    def new; end

    def create
      @order.attachment.attach(params[:order][:attachment])
      Payment::ApiService.order_check_down(@order.payment_transaction, helpers.storage_path(@order.attachment))
      redirect_to orders_path, notice: 'Прикрепление чека прошло успешно.'
    end


    private

    def set_order
      @order = Order.find(params[:order_id])
    end
  end
end