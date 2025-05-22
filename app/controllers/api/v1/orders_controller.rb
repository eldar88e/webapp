module Api
  module V1
    class OrdersController < Api::V1::BaseController
      def index
        @orders = Order.all
        render json: @orders
      end
    end
  end
end
