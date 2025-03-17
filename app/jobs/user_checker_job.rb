class UserCheckerJob < ApplicationJob
  queue_as :default

  def perform(id)
    user   = User.find(id)
    msg    = "🎉 Добро пожаловать на #{Setting.fetch_value(:app_name)}!"
    result = TelegramService.call(msg, user.tg_id)
    return unlock_user_privileges(user) if result.instance_of?(Integer)

    limit_user_privileges(result, user)
  end

  private

  def unlock_user_privileges(user)
    user.update(started: true, is_blocked: false)
    msg = "User #{user.id} started bot"
    Rails.logger.info msg
    TelegramService.call(msg, Setting.fetch_value(:test_id)) # TODO: убрать в дальнейшем
  end
end
