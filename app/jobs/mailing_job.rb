class MailingJob < ApplicationJob
  queue_as :default

  def perform(**args)
    filter  = args[:filter]
    message = args[:message]
    markup  = args[:markup] || {}
    return if message.blank? || Mailing::FILTERS.exclude?(filter)

    clients = fetch_users(filter, args[:user_ids])
    clients.each { |client| process_message(message, client, markup) }
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids)) if filter != 'users'
    # TODO: Реализовать отправку Картинок, видео, репост.
  end

  private

  def process_message(message, client, markup)
    result = TelegramService.call(message, client.tg_id, **markup)
    return limit_user_privileges(result, user) unless result.instance_of?(Integer)

    Message.create(tg_id: user.tg_id, text: message, is_incoming: false, tg_msg_id: result)
    user.update(is_blocked: false, started: true)
    sleep 0.3
  end

  def fetch_users(filter, user_ids)
    case filter.to_sym
    when :users
      User.where(id: user_ids)
    when :add_cart
      User.joins(cart: :cart_items)
          .where.missing(:orders)
          .or(User.where.not(orders: { status: :shipped }))
          .distinct
    when :ordered
      User.joins(:orders).where.not(orders: { id: nil }).distinct
    when :no_ordered
      User.where.missing(:orders).distinct
    when :all
      User.all
    when :is_blocked
      User.where(is_blocked: true)
    else
      []
    end
  end
end
