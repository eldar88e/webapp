class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_authenticate_user!
  skip_before_action :check_started_user!

  layout false

  def update_product_stock
    result = UpdaterProductStockService.process_product(webhook_params)
    return render(json: { success: true }, status: :ok) if result[:success]

    render json: { error: result[:error] }, status: :internal_server_error
  end

  private

  def webhook_params
    params.require(:webhook).permit(:product_id, :product_name, :stock_quantity, :quantity_decrement, :updated_at)
  end
end
