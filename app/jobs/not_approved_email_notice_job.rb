class NotApprovedEmailNoticeJob < ApplicationJob
  queue_as :telegram_notice

  def perform(order_id)
    order = Order.find(order_id)
    user  = order.user
    return if user.orders.where(status: %w[shipped processing]).count < 2

    if user.confirmed_at.blank?
      send_for_not_confirmed(user)
    elsif user.password_sent == false
      SendPasswordJob.perform_later(user.id)
    end
  end

  private

  def send_for_not_confirmed(user)
    msg = build_confirmation_msg(user)
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).deliver_now
    user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'to_catalog' } })
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
