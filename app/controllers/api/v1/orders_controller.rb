module Api
  module V1
    class OrdersController < Api::V1::BaseController
      def index
        @orders = Order.includes(:user, { order_items: [:product] }, :bank_card).order(created_at: :desc)
        render json: @orders, include: {
          user: { only: [:id, :address, :phone, :first_name, :middle_name, :last_name] },
          order_items: {
            only: [:quantity, :price],
            include: {
              product: { only: [:name] }
            }
          },
          bank_card: { only: [:name, :fio] }
        }, only: [:id, :status, :created_at, :shipped_at, :paid_at, :total_amount]
      end
    end
  end
end
