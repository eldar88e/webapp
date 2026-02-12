module Payment
  class CheckStatusService
    STATUSES = {
      approved: { order: :processing, transaction: :approved },
      overdue: { order: :overdue, transaction: :overdue }
    }.freeze

    def initialize(transaction_id, status)
      @transaction = PaymentTransaction.find(transaction_id)
      @status = status
    end

    def self.call(transaction_id, status)
      new(transaction_id, status).check_status
    end

    def check_status
      send "check_#{@status}"
    end

    private

    def check_initialized
      return if @transaction.status != 'initialized'

      status = fetch_status
      return if status.match?('merch_process')
      return update_statuses(:approved) if status.match?('success')

      if status.match?(/system_timer_end_merch_initialized_cancel|merch_cancel/)
        update_statuses(:overdue)
      else
        schedule_next_check
      end
    end

    def check_approved
      return if @transaction.status == 'approved'

      status = fetch_status
      return update_statuses(:approved) if status.match?('success')

      if status == 'trader_check_query'
        @transaction.update!(status: :checking)
        schedule_next_check
        order = @transaction.order
        msg   = "Для подтверждения оплаты по заказу №#{order.id}.\nПожалуйста приложите чек в \
                 формате pdf нажав на кнопку «Приложить чек».".squeeze(' ')
        markup = { markup_url: "/orders/#{order.id}/attachments/new", markup_text: 'Приложить чек' }
        Rails.cache.fetch("check_status_#{@transaction.id}", expires_in: 7.minutes) do
          TelegramService.call(msg, order.user.tg_id, **markup)
        end
      elsif status.match?(/system_timer_end_|admin_appeal_cancel/)
        update_statuses(:overdue)
      else
        schedule_next_check
      end
    end

    def fetch_status
      response = Payment::ApiService.order_get_status(@transaction)
      response&.dig('data', 'status', 'status')
    end

    def update_statuses(statuses)
      ActiveRecord::Base.transaction do
        @transaction.update!(status: STATUSES[statuses][:transaction])
        @transaction.order.update!(status: STATUSES[statuses][:order])
      end
    end

    def schedule_next_check
      puts '*' * 30
      puts "Status: #{@status}"
      puts '=' * 30
      Payment::CheckStatusJob.set(wait: 15.seconds).perform_later(@transaction.id, @status)
    end
  end
end
