class SubscribersNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    product     = Product.find(id)
    subscribers = product&.subscribers
    return if subscribers.blank?

    subscribers.each do |user|
      TelegramJob.perform_later(
        msg: "📢 Товар '#{product.name}' снова в наличии! Спешите заказать!",
        id: user.tg_id,
        markup_url: "products_#{product.id}",
        markup_text: product.name
      )
    end
    product.product_subscriptions.destroy_all
  end
end
