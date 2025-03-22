class MailingJob < ApplicationJob
  queue_as :default

  def perform(**args)
    filter  = args[:filter]
    message = args[:message]
    markup  = args[:markup] || {}
    users   = FetchUsersService.new(filter, args[:user_ids]).call
    users.each do |user|
      user.messages.create(text: message, is_incoming: false, data: { markup: markup })
      sleep 0.3
    end

    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids))
    Mailing.find(args[:id]).update(completed: true)
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
