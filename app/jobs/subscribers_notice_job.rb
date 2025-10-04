class SubscribersNoticeJob < ApplicationJob
  queue_as :default

  def perform(id)
    product = Product.find(id)
    message = form_message(product)
    product.subscribers.each { |user| send_message(user, message) }
    product.product_subscriptions.destroy_all
    notify_admin(product)
  end

  private

  def notify_admin(product)
    msg = "🎉 Уведомление о поступлении '#{product.name}' успешно отправлено всем подписчикам на данный товар."
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids)) if product.subscribers.any?
  end

  def form_message(product)
    text   = "📢 Товар '#{product.name}' снова в наличии! Успейте заказать."
    markup = { markup_url: "products_#{product.id}", markup_text: "Заказать #{product.name}" }
    Tg::MessageService.build_tg_message(product, text, markup)
  end

  def send_message(user, message)
    msg = user.messages.create(**message)
    Tg::MessageService.update_file_id(msg)
    sleep 0.3
  end
end
