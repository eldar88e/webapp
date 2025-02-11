class AbandonedOrderReminderJob < ApplicationJob
  queue_as :default
  STEPS = { one: { wait: 48.hours, msg_type: :two }, two: { wait: 3.hours, msg_type: :overdue } }.freeze

  def perform(**args)
    return if args[:order_id].blank? || args[:msg_type].blank?

    order_id      = args[:order_id]
    current_order = Order.find_by(id: order_id)
    return if current_order.nil? || current_order.status != 'unpaid'

    current_user  = current_order.user
    current_tg_id = current_user.tg_id
    msg           = form_msg(args[:msg_type], current_order, current_user)
    if args[:msg_type] == :overdue
      current_order.update(status: args[:msg_type])
    else
      TelegramMsgDelService.remove(current_tg_id, current_order.msg_id)
      msg_id = TelegramService.call(msg, current_tg_id, markup: 'i_paid')
      save_msg_id(msg_id, current_order, args)
    end
  end

  private

  def save_msg_id(msg_id, order, args)
    user = order.user
    if msg_id.instance_of?(Integer)
      user.update(is_blocked: false)
      order.update_columns(msg_id: msg_id)
      set_reminders(args)
    else
      if msg_id.instance_of?(Telegram::Bot::Exceptions::ResponseError)
        Rails.logger.error "User #{user.id} is blocked"
        user.update(is_blocked: true)
      else
        Rails.logger.error "Error save msg_id for user #{user.id}, msg send result: #{msg_id}"
      end
    end
  end

  def set_reminders(args)
    next_step = STEPS[args[:msg_type]]
    return unless next_step

    AbandonedOrderReminderJob.set(wait: next_step[:wait])
                            .perform_later(order_id: args[:order_id], msg_type: next_step[:msg_type])
  end

  def form_msg(msg_type, order, user)
    card = Setting.fetch_value(:card)
    "#{I18n.t("tg_msg.unpaid.reminder.#{msg_type}", order: order.id)}\n\n" + I18n.t(
      'tg_msg.unpaid.main',
      card: card,
      price: order.total_amount,
      items: order.order_items_str,
      address: user.full_address,
      postal_code: user.postal_code,
      fio: user.full_name,
      phone: user.phone_number
    )
  end
end
