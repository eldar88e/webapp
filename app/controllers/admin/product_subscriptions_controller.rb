module Admin
  class ProductSubscriptionsController < Admin::ApplicationController
    def index
      subscriptions = ProductSubscription.order(created_at: :desc)
      @pagy, @product_subscriptions = pagy(subscriptions, items: 20)
    end
  end
end
