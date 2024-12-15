module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!

    def login
      return redirect_to admin_dashboard_path if current_user

      render layout: 'admin_authorize'
    end

    def index
      redirect_to admin_login_path unless user_signed_in?

      @total_orders = Order.count

      if @total_orders.zero?
        @percentages = {}
      else
        @percentages = Order.statuses.keys.each_with_object({}) do |status, hash|
          status_count = Order.where(status: Order.statuses[status]).count
          hash[status.to_sym] = ((status_count.to_f / @total_orders) * 100).round(2)
        end
      end
    end
  end
end
