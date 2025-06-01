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
      #{user.first_name}, вам начислено #{bonus}₽ кэшбэка за ваш заказ №#{user.orders.last.id}

      Спасибо, что вы с нами!
    TEXT
    data = { markup: { markup: 'to_catalog' } }
    { text: text, is_incoming: false, data: data }
  end

  def send_message(user, message)
    user.messages.create(**message)
  end
end
