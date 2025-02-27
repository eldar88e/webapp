module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index login]
    skip_before_action :authorize_admin_access!, only: %i[index login]

    def index
      # return redirect_to admin_login_path unless user_signed_in?
      return render 'admin/dashboard/login', layout: 'admin_authorize' unless user_signed_in?

      redirect_to_telegram unless current_user.admin_or_moderator_or_manager?
    end

    def show
      start_date      = Date.current.beginning_of_month
      end_date        = Date.current.end_of_month
      @totals_by_card = Order.where(paid_at: start_date..end_date).group(:bank_card_id).sum(:total_amount)
      @bank_cards     = BankCard.all
    end

    def login
      # TODO: удалить!
      return redirect_to admin_path if current_user

      render layout: 'admin_authorize'
    end
  end
end
