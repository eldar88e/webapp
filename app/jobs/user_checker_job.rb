class UserCheckerJob < ApplicationJob
  queue_as :default

  def perform(id)
    user   = User.find(id)
    msg    = "🎉 Добро пожаловать на #{Setting.fetch_value(:app_name)}!"
    result = TelegramService.call(msg, user.tg_id)

    if result.instance_of?(Integer)
      user.update(started: true, is_blocked: false)
      msg = "User #{user.id} started bot"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
    else
      update_user_status(result, user)
    end
  end

  private

  def update_user_status(error, user)
    if error.message.include?('chat not found')
      user.update(started: false)
    elsif error.message.include?('bot was blocked')
      user.update(is_blocked: true)
    end
  end
end
