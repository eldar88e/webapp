class UserBonusNoticeJob < ApplicationJob
  queue_as :default

  def perform(id, bonus)

    user    = User.find(id)
    message = form_message(user, bonus)
    send_message(user, message)
  end

  private

  def form_message(user, bonus)
    text = <<~TEXT.squeeze(' ').chomp
      Здравствуйте, #{user.full_name}!

      Мы рады сообщить, что на ваш бонусный счёт был добавлен бонус в размере #{bonus}₽.

      Ваш текущий баланс бонусов теперь составляет #{user.bonus_balance}₽.
      Эти бонусы могут быть использованы для оплаты заказов.

      Спасибо, что выбираете нас!
      С уважением,
      #{Setting.fetch_value(:app_name)}
    TEXT
    data = { markup: { markup: 'to_catalog' } }
    { text: text, is_incoming: false, data: data }
  end

  def send_message(user, message)
    user.messages.create(**message)
  end
end
