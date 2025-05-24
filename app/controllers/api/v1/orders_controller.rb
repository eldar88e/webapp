module Api
  module V1
    class OrdersController < Api::V1::BaseController
      def index
        orders = Order.includes(:user, { order_items: [:product] }, :bank_card).order(created_at: :desc)
        render json: Panko::ArraySerializer.new(orders, each_serializer: OrderSerializer).to_json
      end
    end
  end
end
