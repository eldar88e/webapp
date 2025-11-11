module Admin
  class BankCardsController < Admin::ApplicationController
    include Admin::ResourceConcerns

    def index
      @q_bank_cards      = BankCard.order(active: :desc, name: :asc).ransack(params[:q])
      @pagy, @bank_cards = pagy @q_bank_cards.result
    end

    def statistics
      @start_date = params[:start_date] ? params[:start_date].to_date : Date.current.beginning_of_month
      @end_date   = params[:end_date] ? params[:end_date].to_date : Date.current.end_of_month
      @bank_cards = BankCard.all
      form_totals_by_card
    end

    private

    def bank_card_params
      params.require(:bank_card).permit(:name, :number, :fio, :active)
    end

    def form_totals_by_card
      totals_by_card = Order.where(paid_at: @start_date..@end_date).group(:bank_card_id).sum(:total_amount)
      unknown_bank   = totals_by_card.delete(nil)
      @bank_cards.each { |bank_card| totals_by_card[bank_card.id] ||= 0 }
      @totals_by_card = totals_by_card.sort_by { |_k, v| v }.to_h
      @totals_by_card[:unknown] = unknown_bank
    end
  end
end
