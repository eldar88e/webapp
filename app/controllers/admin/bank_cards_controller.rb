module Admin
  class BankCardsController < Admin::ApplicationController
    include Admin::ResourceConcerns

    def index
      @q_bank_cards      = BankCard.order(active: :desc, name: :asc).ransack(params[:q])
      @pagy, @bank_cards = pagy @q_bank_cards.result
    end

    private

    def bank_card_params
      params.require(:bank_card).permit(:name, :number, :fio, :active)
    end
  end
end
