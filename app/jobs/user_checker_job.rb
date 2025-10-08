class UserCheckerJob < ApplicationJob
  queue_as :default

  def perform(id)
    user   = User.find(id)
    msg    = "🎉 Добро пожаловать #{user.first_name || user.first_name_raw} на #{Setting.fetch_value(:app_name)}!"
    result = TelegramService.call(msg, user.tg_id, markup: 'mailing')
    if result.instance_of?(Integer)
      user.update(started: true, is_blocked: false)
      msg = "User #{user.id} started bot with webapp"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
      # TODO: убрать со временем уведомление админа
    end

    limit_user_privileges(result, user)
  end
end
