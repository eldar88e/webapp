class AbandonedOrderReminderJob < ApplicationJob
  queue_as :default
  STEPS = { one: { wait: 48.hours, msg_type: :two }, two: { wait: 3.hours, msg_type: :overdue } }.freeze

  def perform(**args)
    return if args[:msg_type].blank?

    order = Order.find_by(id: args[:order_id])
    return if order.nil? || order.status != 'unpaid'

    process_remainder(args, order)
  end

  private

  def process_remainder(args, order)
    return if handle_overdue_status_if_blocked?(order, args)

    # tg не дает боту удалить сообщения старше 48 часов
    TelegramMsgDelService.remove(order.user.tg_id, order.msg_id) if args[:msg_type] != :two
    update_bank_card(order)
    msg = form_msg(args[:msg_type], order)
    order.user.messages.create(**msg)
    schedule_reminders(args)
    # msg_id = TelegramService.call(msg, tg_id, markup: 'i_paid')
    # save_msg_id(msg_id, order, args)
  end

  def handle_overdue_status_if_blocked?(order, args)
    return false if args[:msg_type].to_s != 'overdue' || !order.user.is_blocked?

    order.update(status: :overdue)
    true
  end

  def update_bank_card(order)
    return if BankCard.cached_available_ids.any?(order.bank_card_id)

    order.update_columns(bank_card_id: BankCard.sample_bank_card_id)
  end

  ############# TODO: удалить
  def save_msg_id(msg_id, order, args)
    user = order.user
    if msg_id.instance_of?(Integer)
      user.update(is_blocked: false, started: true)
      order.update_columns(msg_id: msg_id)
      schedule_reminders(args)
    else
      limit_user_privileges(msg_id, user)
      order.update(status: :overdue)
    end
  end
  #############

  def schedule_reminders(args)
    next_step = STEPS[args[:msg_type]]
    return if next_step.blank?

    AbandonedOrderReminderJob.set(wait: next_step[:wait])
                             .perform_later(order_id: args[:order_id], msg_type: next_step[:msg_type])
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
