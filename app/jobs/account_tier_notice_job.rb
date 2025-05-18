class AccountTierNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    user = User.find(id)
    return if user.account_tier.blank?

    message = form_message(user)
    user.messages.create(**message)
  end

  private

  def form_message(user)
    text = form_text(user)
    data = { markup: { markup: 'to_catalog' } }
    { text: text, is_incoming: false, data: data }
  end

  def form_text(user)
    return <<~TEXT.squeeze(' ').chomp if user.account_tier.bonus_percentage == 1
      💚 Поздравляем, вы стали участником нашей системы лояльности!

      Теперь при заказах от #{Setting.fetch_value(:bonus_threshold)}₽ — #{user.account_tier.bonus_percentage}% \
      кэшбэка поступает на ваш бонусный счёт.
    TEXT

    <<~TEXT.squeeze(' ').chomp
      💚 Ваш уровень повышен до «#{user.account_tier.title}».
      Теперь вы получаете #{user.account_tier.bonus_percentage}% кэшбэка на сумму заказа от \
      #{Setting.fetch_value(:bonus_threshold)}₽!
    TEXT
  end
end
