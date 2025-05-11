class AccountTierNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    user    = User.find(id)
    message = form_message(user)
    send_message(user, message)
  end

  private

  def form_message(user)
    text =
      if user.account_tier.bonus_percentage == 1
        <<~TEXT.squeeze(' ').chomp
          💚 Поздравляем, вы стали участником нашей системы лояльности!

          Теперь при заказах от #{Setting.fetch_value(:bonus_threshold)}₽ — #{user.account_tier.bonus_percentage}% \
          кэшбэка поступает на ваш бонусный счёт.
        TEXT
      else
        <<~TEXT.squeeze(' ').chomp
          💚 Ваш уровень повышен до «#{user.account_tier.title}».
          Теперь вы получаете #{user.account_tier.bonus_percentage}% кэшбэка на сумму заказа от #{Setting.fetch_value(:bonus_threshold)}₽!
        TEXT
      end
    data = { markup: { markup: 'to_catalog' } }
    { text: text, is_incoming: false, data: data }
  end

  def send_message(user, message)
    user.messages.create(**message)
  end
end
