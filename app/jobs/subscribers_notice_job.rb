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
    msg    = { text: text, is_incoming: false, data: { markup: markup } }
    return msg unless product.image.attached?

    tg_media = find_or_create_tg_media(product)
    msg[:data][:type] = 'image'
    tg_media.file_id ? msg[:data][:tg_file_id] = tg_media.file_id : msg[:data][:media_id] = tg_media.id
    msg
  end

  def find_or_create_tg_media(product)
    file_hash = Digest::MD5.hexdigest(product.image.download)
    TgMediaFile.fetch_or_create_by_hash(
      file_hash: file_hash,
      file_type: product.image.blob.content_type,
      original_filename: product.image.blob.filename,
      attachment: product.image.blob
    )
  end

  def send_message(user, message)
    msg = user.messages.create(**message)
    Tg::FileService.update_file_id(msg)
    sleep 0.3
  end
end
