class MailingJob < ApplicationJob
  queue_as :default

  def perform(**args)
    mailing = Mailing.find(args[:id])
    users   = FetchUsersService.call(mailing.target, args[:user_ids])
    users.find_each { |user| save_message(user, mailing) }
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids))
    mailing.update(completed: true)
  end

  private

  def save_message(user, mailing)
    user.messages.create(text: mailing.message, is_incoming: false, data: mailing.data)
    update_tg_file_id(mailing) if mailing.data['tg_file_id'].blank?
    sleep 0.3
  end

  def update_tg_file_id(mailing)
    return if mailing.data['media_id'].blank?

    tg_media_file = TgMediaFile.find_by(id: mailing.data['media_id'])
    return if tg_media_file&.file_id.blank?

    mailing.data['tg_file_id'] = tg_media_file.file_id
    mailing.save!
  end
end
