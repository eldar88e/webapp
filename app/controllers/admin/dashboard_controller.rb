module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!, :authorize_admin_access!, only: :index

    def index
      # return render 'admin/dashboard/login', layout: 'admin_authorize' unless user_signed_in?
      return redirect_to new_user_session_path unless user_signed_in?

      redirect_to_telegram unless current_user.admin_or_moderator_or_manager?
    end

    def show
      @start_date = params[:start_date] ? params[:start_date].to_date : Date.current.beginning_of_month
      @end_date   = params[:end_date] ? params[:end_date].to_date : Date.current.end_of_month
      @bank_cards = BankCard.all
      form_totals_by_card
    end

    private

    def form_totals_by_card
      totals_by_card = Order.where(paid_at: @start_date..@end_date).group(:bank_card_id).sum(:total_amount)
      unknown_bank   = totals_by_card.delete(nil)
      @bank_cards.each { |bank_card| totals_by_card[bank_card.id] ||= 0 }
      @totals_by_card = totals_by_card.sort_by { |_k, v| v }.to_h
      @totals_by_card[:unknown] = unknown_bank
    end
  end
end
