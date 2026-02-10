module Payment
  class ReminderService
    STEPS = {
      'one' => { 'wait' => 10.minutes, 'msg_type' => 'two' },
      'two' => { 'wait' => 5.second, 'msg_type' => 'exit' }
    }.freeze

    def initialize(**args)
      @order    = Order.find(args[:order_id])
      @msg_type = args[:msg_type]
    end

    def self.call(**args)
      new(**args).send_reminder
    end

    def send_reminder
      return if @order.status != 'unpaid'
      return if @msg_type == 'exit'

      remove_old_msg
      msg     = form_msg
      message = @order.user.messages.create(**msg)
      @order.update_columns(msg_id: message.id, tg_msg: false)

      step = STEPS[@msg_type]
      Payment::ReminderJob.set(wait: step['wait']).perform_later(order_id: @order.id, msg_type: step['msg_type'])
    end

    private

    def remove_old_msg
      return if @order.msg_id.blank?

      if @order.tg_msg.present?
        TelegramMsgDelService.remove(@order.user.tg_id, @order.msg_id)
      else
        @order.user.messages.find_by(id: @order.msg_id)&.destroy
      end
    end

    def form_msg
      user = @order.user
      payment_transaction = @order.payment_transaction
      text = "#{I18n.t("tg_msg.unpaid.reminder.#{@msg_type}", order: @order.id)}\n\n" + I18n.t(
        'tg_msg.unpaid.main',
        card: payment_transaction.card_number,
        bank: payment_transaction.bank_name,
        fio_card: payment_transaction.card_people,
        price: @order.total_amount.to_i,
        items: @order.order_items_str,
        address: user.full_address, postal_code: user.postal_code, fio: user.full_name, phone: user.phone_number
      ) + "\n\n#{I18n.t('tg_msg.unpaid.reminder.footer')}"
      { text: text, is_incoming: false, data: { markup: { markup: 'i_paid' } } }
    end
  end
end
