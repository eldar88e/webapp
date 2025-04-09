module Admin
  class ProductSubscriptionsController < Admin::ApplicationController
    def index
      @pagy, @product_subscriptions = pagy ProductSubscription.includes(:user, :product).order(created_at: :desc)
    end

    def destroy
      @product_subscription = ProductSubscription.find(params[:id])
      @product_subscription.destroy
      redirect_to admin_product_subscriptions_path, notice: t('.success')
    end
  end
end
