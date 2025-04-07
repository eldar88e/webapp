class MailingJob < ApplicationJob
  queue_as :default

  def perform(**args)
    mailing = Mailing.find(args[:id])
    users   = FetchUsersService.new(mailing.target, args[:user_ids]).call
    users.each { |user| save_message(user, mailing) }
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids))
    mailing.update(completed: true)
  end

  private

  def save_message(user, mailing)
    user.messages.create(text: mailing.message, is_incoming: false, data: mailing.data)
    update_tg_file_id(mailing)
    sleep 0.3
  end

  def update_tg_file_id(mailing)
    return unless mailing.data['media_id'] && mailing.data['tg_file_id'].blank?

    tg_media_file = TgMediaFile.find_by(id: mailing.data['media_id'])
    mailing.data['tg_file_id'] = tg_media_file.file_id if tg_media_file&.file_id.present?
  end

  def process_message(message, user, markup)
    result = TelegramService.call(message, user.tg_id, **markup)
    return limit_user_privileges(result, user) unless result.instance_of?(Integer)

    Message.create(tg_id: user.tg_id, text: message, is_incoming: false, tg_msg_id: result)
    user.update(is_blocked: false, started: true)
    sleep 0.3
  end
end
