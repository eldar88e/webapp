module Admin
  class BankCardsController < Admin::ApplicationController
    before_action :set_bank_card, only: %i[edit update]

    def index
      @bank_cards = BankCard.order(:created_at)
    end

    def new
      @bank_card = BankCard.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить банковскую карту'),
        turbo_stream.update(:modal_body, partial: '/admin/bank_cards/form', locals: { method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Изменить банковскую карту'),
        turbo_stream.update(:modal_body, partial: '/admin/bank_cards/form', locals: { method: :patch })
      ]
    end
    def create
      @bank_card = BankCard.new(bank_card_params)

      if @bank_card.save
        redirect_to admin_bank_cards_path, notice: t('controller.bank_cards.create')
      else
        error_notice(@bank_card.errors.full_messages, :unprocessable_entity)
      end
    end

    def update
      if @bank_card.update(bank_card_params)
        render turbo_stream: [
          turbo_stream.replace(@bank_card, partial: '/admin/bank_cards/bank_card', locals: { bank_card: @bank_card }),
          success_notice(t('controller.bank_cards.update'))
        ]
      else
        error_notice(@bank_card.errors.full_messages, :unprocessable_entity)
      end
    end


    private

    def set_bank_card
      @bank_card = BankCard.find(params[:id])
    end

    def bank_card_params
      params.require(:bank_card).permit(:name, :number, :fio, :active)
    end
  end
end
