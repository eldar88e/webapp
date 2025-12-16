class AbandonedOrderReminderJob
  include Sidekiq::Worker

  sidekiq_options queue: :default,
                  lock: :until_executed,
                  lock_args: ->(args) { [args.first] },
                  retry: 3

  STEPS = {
    'one' => { 'wait' => 48.hours, 'msg_type' => 'two' },
    'two' => { 'wait' => 3.hours, 'msg_type' => 'overdue' }
  }.freeze

  def perform(args)
    return if args['msg_type'].blank?

    order = Order.find_by(id: args['order_id'])
    return if order&.status != 'unpaid' ||
              order.order_items_with_product.any? { |i| i.product.stock_quantity < i.quantity }

    process_remainder(args, order)
  end

  private

  def process_remainder(args, order)
    return if handle_overdue_status_if_blocked?(order, args)

    # tg не дает боту удалить сообщения старше 48 часов
    remove_old_msg(order) # if args['msg_type'] != 'two'
    update_bank_card(order)
    msg = form_msg(args['msg_type'], order)
    message = order.user.messages.create(**msg)
    order.update_columns(msg_id: message.id, tg_msg: false)
    schedule_reminders(args)
  end

  def remove_old_msg(order)
    return if order.msg_id.blank?

    if order.tg_msg.present?
      TelegramMsgDelService.remove(order.user.tg_id, order.msg_id)
    else
      order.user.messages.find_by(id: order.msg_id)&.destroy
    end
  end

  def handle_overdue_status_if_blocked?(order, args)
    return false if args['msg_type'].to_s != 'overdue' && !order.user.is_blocked?

    order.update(status: :overdue)
    true
  end

  def update_bank_card(order)
    return if BankCard.cached_available_ids.any?(order.bank_card_id)

    order.update_columns(bank_card_id: BankCard.sample_bank_card_id)
  end

  def schedule_reminders(args)
    next_step = STEPS[args['msg_type']]
    return if next_step.blank?

    AbandonedOrderReminderJob.set(wait: next_step['wait'])
                             .perform_async({ 'order_id' => args['order_id'], 'msg_type' => next_step['msg_type'] })
  end

  def form_msg(msg_type, order)
    user = order.user
    card = order.bank_card.bank_details
    text = "#{I18n.t("tg_msg.unpaid.reminder.#{msg_type}", order: order.id)}\n\n" + I18n.t(
      'tg_msg.unpaid.main',
      card: card, price: order.total_amount, items: order.order_items_str,
      address: user.full_address, postal_code: user.postal_code, fio: user.full_name, phone: user.phone_number
    )
    { text: text, is_incoming: false, data: { markup: { markup: 'i_paid' } } }
  end
end
