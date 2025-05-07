class AccountTierNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    user    = User.find(id)
    message = form_message(user)
    send_message(user, message)
  end

  private

  def form_message(user)
    text = "🎉 Ваш уровень повышен до '#{user.account_tier.title}'!"
    data = { markup: :to_catalog }
    { text: text, is_incoming: false, data: data }
  end

  def send_message(user, message)
    user.messages.create(**message)
  end
end
