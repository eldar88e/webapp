module Payment
  class CheckStatusService
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

      if status.match?('system_timer_end_merch_initialized_cancel')
        set_order_overdue
      else
        schedule_next_check
      end
    end

    def check_approved
      return if @transaction.status == 'approved'

      status = fetch_status
      return set_order_approved if status.match?('success')

      if status.match?('trader_check_query')
        @transaction.update!(status: :check)
        schedule_next_check
        order  = @transaction.order
        msg    = "Для подтверждения оплаты пожалуйста приложите чек в формате pdf нажав на кнопку «Приложить чек»."
        markup = { markup_url: "/order/#{order.id}/attach_check", markup_text: 'Приложить чек' }
        TelegramService.call(msg, order.user.tg_id, **markup)
      elsif status.match?('system_timer')
        set_order_overdue
      else
        schedule_next_check
      end
    end

    def fetch_status
      response = Payment::ApiService.order_get_status(@transaction)
      response&.dig('data', 'status', 'status')
    end

    def set_order_approved
      ActiveRecord::Base.transaction do
        @transaction.update!(status: :approved)
        @transaction.order.update!(status: :processing)
      end
    end

    def set_order_overdue
      ActiveRecord::Base.transaction do
        @transaction.update!(status: :overdue)
        @transaction.order.update!(status: :overdue)
      end
    end

    def schedule_next_check
      puts '*' * 30
      puts "Status: #{status}"
      puts '=' * 30
      Payment::CheckStatusJob.set(wait: 15.seconds).perform_later(@transaction.id, @status)
    end
  end
end
