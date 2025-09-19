module Admin
  class PurchaseItemsController < Admin::ApplicationController
    before_action :set_purchase, only: %i[create update]

    def create
      if @purchase.save && @purchase.purchase_items.create!(purchase_item_params)
        render turbo_stream: [
          success_notice(t('.create')),
          turbo_stream.replace("buy_btn_#{params[:product_id]}", html: '')
        ]
      else
        error_notice(@purchase.errors.full_messages)
      end
    end

    def update
      if @purchase.update(purchase_params)
        redirect_to admin_purchases_path, notice: t('.update')
      else
        error_notice(@purchase.errors.full_messages)
      end
    end

    private

    def set_purchase
      @purchase = Purchase.find_by(status: 'initialized') || Purchase.new
    end

    def purchase_item_params
      params.permit(:product_id, :quantity)
    end
  end
end
