class NotApprovedEmailNoticeJob < ApplicationJob
  queue_as :telegram_notice

  def perform(order_id)
    order = Order.find(order_id)
    user  = order.user
    return if user.orders.where(status: %w[shipped processing]).count < 2

    if user.confirmed_at.blank?
      send_for_not_confirmed(user)
    elsif user.password_sent == false
      send_for_not_send_pass(user)
    end
  end

  private

  def send_for_not_confirmed(user)
    msg = build_confirmation_msg(user)
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).deliver_now
    user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'to_catalog' } })
  end

  def send_for_not_send_pass(user)
    password = Devise.friendly_token[0, 12]
    user.update!(password: password)
    PassMailer.send_pass(user, user.password).deliver_now
    send_to_telegram(user, password)
    user.update!(password_sent: true)
  end

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

  def build_confirmation_msg(user)
    <<~TEXT.squeeze(' ').chomp
      Уважаемый(ая) #{user.first_name},
      мы заметили, что Вы ещё не подтвердили свой e-mail.
      Вам было отправлено письмо с инструкциями по подтверждению.\n
      Пожалуйста, подтвердите почту — так Вы сможете:\n
      ✅ получать уведомления о заказах и акциях,\n
      ✅ восстановить доступ к аккаунту при необходимости,\n
      ✅ и оставаться на связи, если вдруг Telegram перестанет работать в России.
    TEXT
  end
end
