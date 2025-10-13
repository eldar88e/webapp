class NotApprovedEmailNoticeJob < ApplicationJob
  queue_as :telegram_notice

  MSG = <<~TEXT.squeeze(' ').chomp
    мы заметили, что Вы ещё не подтвердили свой e-mail.
    Вам было отправлено письмо с инструкциями по подтверждению.

    Пожалуйста, подтвердите почту — так Вы сможете:

    ✅ получать уведомления о заказах и акциях,

    ✅ восстановить доступ к аккаунту при необходимости,

    ✅ и оставаться на связи, если вдруг Telegram перестанет работать в России.
  TEXT

  def perform(order_id)
    order = Order.find(order_id)
    user  = order.user
    return if user.confirmed_at.present? || user.orders.where(status: 'shipped').count < 2

    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).deliver_now
    msg = "Уважаемый(ая) #{user.first_name},\n" + MSG
    user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'to_catalog' } })
  end
end
