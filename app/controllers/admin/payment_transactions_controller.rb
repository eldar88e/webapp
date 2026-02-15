module Admin
  class PaymentTransactionsController < Admin::ApplicationController
    def index
      @pagy, @resources = pagy PaymentTransaction.includes(order: :attachment_attachment).order(created_at: :desc)
    end

    def show
      @resource = PaymentTransaction.find(params[:id])
    end
  end
end
