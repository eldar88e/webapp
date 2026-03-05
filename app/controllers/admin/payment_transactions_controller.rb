module Admin
  class PaymentTransactionsController < Admin::ApplicationController
    before_action :set_resource, only: %i[show update destroy]

    def index
      @pagy, @resources = pagy PaymentTransaction.includes(order: :attachment_attachment).order(created_at: :desc)
    end

    def show; end

    def update
      if params[:cancel].present?
        response = Payment::ApiService.order_cancel(@resource)
        if response['response'] == 'success'
          redirect_to admin_orders_path, alert: t('.cancelled')
        else
          error_notice(response['message'])
        end
      else
        error_notice t('.error')
      end
    end

    def destroy
      @resource.destroy!
      redirect_to admin_orders_path, notice: t('.destroy')
    end

    private

    def set_resource
      @resource = PaymentTransaction.find(params[:id])
    end
  end
end
