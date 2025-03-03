class MailingJob < ApplicationJob
  queue_as :default

  def perform(**args)
    filter  = args[:filter]
    message = args[:message]
    markup  = args[:markup] || {}
    return if message.blank? || Mailing::FILTERS.exclude?(filter)

    users = FetchUsersService.new(filter, args[:user_ids]).call
    users.each { |user| process_message(message, user, markup) }
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids)) if filter != 'users'
    # TODO: Реализовать отправку Картинок, видео, репост.
  end

  private

  def process_message(message, user, markup)
    result = TelegramService.call(message, user.tg_id, **markup)
    return limit_user_privileges(result, user) unless result.instance_of?(Integer)

    Message.create(tg_id: user.tg_id, text: message, is_incoming: false, tg_msg_id: result)
    user.update(is_blocked: false, started: true)
    sleep 0.3
  end
end
