class SubscribersNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    product     = Product.find(id)
    subscribers = product&.subscribers
    return if subscribers.blank?

    subscribers.each { |user| run_telegram_job(user, product) }
    product.product_subscriptions.destroy_all
  end

  private

  def run_telegram_job(user, product)
    TelegramJob.perform_later(
      msg: "📢 Товар '#{product.name}' снова в наличии! Успейте заказать.",
      id: user.tg_id,
      markup_url: "products_#{product.id}",
      markup_text: "Заказать #{product.name}"
    )
  end
end
