module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!, :authorize_admin_access!, only: :index

    def index
      return render 'admin/dashboard/login', layout: 'admin_authorize' unless user_signed_in?

      redirect_to_telegram unless current_user.admin_or_moderator_or_manager?
    end

    def show
      start_date      = Date.current.beginning_of_month
      end_date        = Date.current.end_of_month
      @totals_by_card = Order.where(paid_at: start_date..end_date).group(:bank_card_id)
                             .sum(:total_amount)
      @bank_cards     = BankCard.all
    end
  end
end
