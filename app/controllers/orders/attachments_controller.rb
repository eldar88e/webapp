module Orders
  class AttachmentsController < ApplicationController
    before_action :set_order
    before_action :check_order_status, only: :create

    def new; end

    def create
      file = params.dig(:order, :attachment)
      return redirect_to orders_path, alert: t('.invalid_format') unless file&.content_type == 'application/pdf'

      @order.attachment.attach(file)
      # Payment::AttachmentJob.perform_later(@order.id)

      redirect_to orders_path, notice: t('.success')
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
