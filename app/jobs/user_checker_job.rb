class UserCheckerJob < ApplicationJob
  queue_as :default

  def perform(id)
    user = User.find(id)
    name = user.first_name || user.first_name_raw
    msg  = "🎉 Добро пожаловать #{name} на #{Setting.fetch_value(:app_name).capitalize}!"
    result = TelegramService.call(msg, user.tg_id, markup: 'first_msg')
    # user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'first_msg' } })
    return user.update(started: true, is_blocked: false) if result.instance_of?(Integer)

    limit_user_privileges(result, user)
  end
end
