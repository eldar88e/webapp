class SendPasswordJob < ApplicationJob
  queue_as :telegram_notice

  def perform(user_id)
    user     = User.find(user_id)
    password = Devise.friendly_token[0, 12]
    user.update!(password: password)
    PassMailer.send_pass(user).deliver_now
    send_to_telegram(user, password)
    user.update!(password_sent: true)
  end

  private

  def send_to_telegram(user, password)
    enter_url = "https://#{ENV.fetch('HOST')}/users/sign_in"
    markup    = { markup: 'to_catalog' }
    site_link = { markup_ext_url: enter_url, markup_ext_text: 'Войти через сайт' }
    markup.merge!(site_link) if Rails.env.production?
    msg = build_msg(user, password, enter_url)
    user.messages.create(text: msg, is_incoming: false, data: { markup: markup })
  end

  def build_msg(user, password, enter_url)
    <<~TEXT.squeeze(' ').chomp
      Уважаемый(ая) #{user.first_name},
      🎉 рады приветствовать Вас на #{Setting.fetch_value(:app_name)}!\n
      Ваш пароль: `#{password}`\n\nСсылка для входа: #{enter_url}
    TEXT
  end
end
