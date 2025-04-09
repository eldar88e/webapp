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
    text = "📢 Товар '#{product.name}' снова в наличии! Успейте заказать."
    data = { markup: { markup_url: "products_#{product.id}", markup_text: "Заказать #{product.name}" } }
    return { text: text, is_incoming: false, data: data } unless product.image.attached?

    tg_media    = find_or_create_tg_media(product)
    data[:type] = 'image'
    tg_media.file_id ? data[:tg_file_id] = tg_media.file_id : data[:media_id] = tg_media.id
    { text: text, is_incoming: false, data: data }
  end

  def find_or_create_tg_media(product)
    file_hash = Digest::MD5.hexdigest(product.image.download)
    TgMediaFile.find_or_create_by!(file_hash: file_hash) do |media|
      media.file_type         = product.image.blob.content_type
      media.original_filename = product.image.blob.filename
      media.attachment.attach(product.image.blob)
    end
  end

  def send_message(user, message)
    user.messages.create(**message)
    update_tg_file_id(message)
    sleep 0.3
  end

  def update_tg_file_id(message)
    return unless message[:data][:media_id] && message[:data][:tg_file_id].blank?

    tg_media_file = TgMediaFile.find_by(id: message[:data][:media_id])
    message[:data][:tg_file_id] = tg_media_file.file_id if tg_media_file&.file_id.present?
  end
end
