class MailingJob < ApplicationJob
  queue_as :default
  MARKUP = 'mailing'.freeze

  def perform(**args)
    filter  = args[:filter]
    message = args[:message]
    return if message.blank? || Mailing::FILTERS.exclude?(filter)

    user_id = args[:user_id]
    return send_message(message, user_id) if user_id && filter == 'user'

    clients = fetch_users(filter)

    clients.each do |client|
      result = TelegramService.call(message, client.tg_id, markup: MARKUP)
      save_message_or_status(result, client, message)
      sleep 0.3
    end
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids))
  end

  private

  def send_message(message, id)
    user  = User.find(id)
    tg_id = user&.tg_id
    return if tg_id.nil?

    result = TelegramService.call(message, tg_id)
    save_message_or_status(result, user, message)
  end

  def fetch_users(filter)
    case filter.to_sym
    when :ordered
      User.joins(:orders).where.not(orders: { id: nil }).distinct
    when :no_ordered
      User.where.missing(:orders).distinct
    when :all
      User.all
    when :is_blocked
      User.where(is_blocked: true)
    end
  end

  def save_message_or_status(result, user, message)
    if result.instance_of?(Integer)
      Message.create(tg_id: user.tg_id, text: message, is_incoming: false, tg_msg_id: result)
      user.update(is_blocked: false)
    else
      return user.update(is_blocked: true) if result.instance_of?(Telegram::Bot::Exceptions::ResponseError)

      Message.create(tg_id: user.tg_id, text: result.message, is_incoming: false)
    end
  end
end
