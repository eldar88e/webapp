class NotApprovedEmailNoticeJob < ApplicationJob
  queue_as :telegram_notice

  MSG = <<~TEXT.squeeze(' ').chomp
    Подтвердите свой адрес электронной почты Мы заметили, что вы ещё не подтвердили свой e-mail.

    Пожалуйста, сделайте это — это поможет:

    ✅ получать уведомления о заказах и акциях,

    ✅ восстановить доступ к аккаунту при необходимости,

    ✅ и оставаться на связи, если вдруг Telegram перестанет работать в России.
  TEXT

  def perform(order_id)
    order = Order.find(order_id)
    user  = order.user
    return if user.confirmed_at.present? || user.orders.where(status: 'shipped').count < 2

    msg = "Уважаемый(ая) #{user.first_name}, " + MSG
    user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'to_catalog' } })
  end
end
