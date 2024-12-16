class AbandonedCartReminderJob < ApplicationJob
  queue_as :default
  TWO_WAIT = 1.minute # 48.hours TODO: исправить
  OVERDUE_WAIT = 1.minute # 3.hours

  def perform(**args)
    binding.pry
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
      TelegramService.delete_msg('', current_tg_id, current_order.msg_id)
      msg_id = TelegramService.call(msg, current_tg_id, markup: 'i_paid')
      current_order.update_columns(msg_id: msg_id)
      if args[:msg_type] == :one
        AbandonedCartReminderJob.set(wait: TWO_WAIT).perform_later(order_id: args[:order_id], msg_type: :two)
      elsif args[:msg_type] == :two
        AbandonedCartReminderJob.set(wait: OVERDUE_WAIT).perform_later(order_id: args[:order_id], msg_type: :overdue)
      end
    end
  end

  private

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
