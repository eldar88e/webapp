class SubscribersNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    product = Product.find(id)
    product.subscribers.each do |user|
      send_message(user, product)
      sleep 0.3
    end
    product.product_subscriptions.destroy_all
    msg = "Уведомление о поступлении #{product.name} успешно отправлено всем подписчикам"
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids)) if product.subscribers.any?
  end

  private

  def send_message(user, product)
    text   = "📢 Товар '#{product.name}' снова в наличии! Успейте заказать."
    markup = { markup_url: "products_#{product.id}", markup_text: "Заказать #{product.name}" }
    user.messages.create(text: text, is_incoming: false, data: { markup: markup })
  end

  # def run_telegram_job(user, product)
  #   TelegramJob.perform_later(
  #     msg: "📢 Товар '#{product.name}' снова в наличии! Успейте заказать.",
  #     id: user.tg_id,
  #     markup_url: "products_#{product.id}",
  #     markup_text: "Заказать #{product.name}"
  #   )
  # end
end
