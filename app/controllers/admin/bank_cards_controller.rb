module Admin
  class BankCardsController < Admin::ApplicationController
    def index
      @bank_cards = BankCard.order(:created_at)
    end
  end
end
