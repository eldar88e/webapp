module Payment
  class CheckStatusService
    TIME_WAIT = 20.seconds
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
      return if @transaction.order.bank_card.present?
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
        handle_trader_check_query
      elsif status.match?(/system_timer_end_|admin_appeal_cancel/)
        update_statuses(:overdue)
      else
        schedule_next_check
      end
    end

    def send_pdf_notice(order)
      Rails.cache.fetch("check_status_#{@transaction.id}", expires_in: 7.minutes) do
        msg = <<~MSG.squeeze(' ')
          Для подтверждения оплаты по заказу №#{order.id}.\n
          Пожалуйста приложите чек в формате pdf нажав на кнопку «Приложить чек».
          Для подтверждения оплаты у вас есть 30 минут с момента первого уведомления.
          После чего заказ будет автоматически отменен. При возникновении проблем свяжитесь с нами.
          Спасибо за понимание!
        MSG
        markup = { markup_url: "/orders/#{order.id}/attachments/new", markup_text: 'Приложить чек' }
        # TelegramService.call(msg, order.user.tg_id, **markup)
        order.user.messages.create(text: msg, is_incoming: false, data: { markup: markup, business: true })
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
      Payment::CheckStatusJob.set(wait: TIME_WAIT).perform_later(@transaction.id, @status)
    end

    def storage_url(attach)
      ApplicationController.helpers.storage_path(attach)
    end

    def handle_trader_check_query
      @transaction.update!(status: :checking)
      schedule_next_check
      result = send_check

      if result && result['response'] != 'success'
        msg = "Error attach check to transaction ##{@transaction.object_token}: #{result}"
        Rails.logger.error msg
        TelegramService.call(msg, Setting.fetch_value(:admin_ids))
      else
        send_pdf_notice(@transaction.order)
      end
    end

    def send_check
      return unless @transaction.order.attachment.attached?

      Payment::ApiService.order_check_down(@transaction, storage_url(@transaction.order.attachment))
    end
  end
end
