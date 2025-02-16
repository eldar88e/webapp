class UserCheckerJob < ApplicationJob
  queue_as :default

  def perform(id)
    user   = User.find(id)
    msg    = "🎉 Добро пожаловать на #{Setting.fetch_value(:app_name)}!"
    result = TelegramService.call(msg, user.tg_id)
    return unless result.instance_of?(Integer)

    user.update(started: true, is_blocked: false)
    msg = "User #{user.id} started bot"
    Rails.logger.info msg
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
  end
end
