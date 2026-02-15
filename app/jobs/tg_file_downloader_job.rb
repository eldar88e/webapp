class TgFileDownloaderJob < ApplicationJob
  queue_as :default

  def perform(**args)
    response = tg_file_id(args)
    user     = User.find_by(tg_id: args[:tg_id])
    return if user.blank? || (response.blank? && args[:msg].blank?)

    file_path = response.presence&.file_path
    process_file(user, file_path, args)
  end

  private

  def process_file(user, file_path, args)
    file_url  = "https://api.telegram.org/file/bot#{Setting.fetch_value(:tg_token)}/#{file_path}"
    tempfile  = FileDownloaderService.call(file_url)
    file_type = Marcel::MimeType.for(tempfile)
    name      = file_path.split('/')&.last
    file_hash = Digest::MD5.hexdigest(tempfile.read)
    tg_file   = find_or_create_tg_file(file_hash, args[:file_id], file_type, name)
    attach_file(tg_file, name, file_type, tempfile) unless tg_file.attachment.attached?
    save_message(user, args, tg_file)
    attach_pdf_to_order(user, tg_file, file_type)
  end

  def save_message(user, args, tg_file)
    # data = { tg_file_id: tg_file.file_id, media_id: tg_file.id }
    data = Tg::MessageService.build_data(tg_file)
    user.messages.create(text: args[:msg], tg_msg_id: args[:msg_id], data: data)
  end

  def find_or_create_tg_file(file_hash, file_id, file_type, name)
    TgMediaFile.fetch_or_create_by_hash(
      file_hash: file_hash,
      file_type: file_type,
      original_filename: name,
      file_id: file_id
    )
  end

  def tg_file_id(args)
    response = nil
    Telegram::Bot::Client.run(Setting.fetch_value(:tg_token)) do |bot|
      response = bot.api.get_file(file_id: args[:file_id])
    end
    response
  end

  def attach_pdf_to_order(user, tg_file, file_type)
    return unless file_type == 'application/pdf'

    order = user.orders.paid.order(created_at: :desc).first
    return if order.blank?

    order.attachment.attach(tg_file.attachment.blob)
    TelegramJob.perform_later(msg: "PDF прикреплён к заказу №#{order.id}", id: user.tg_id)
    msg = "Пользователь ##{user.id} прикрепил PDF к заказу №#{order.id}"
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
  end

  def attach_file(media_file, name, file_type, tempfile)
    tempfile.rewind
    media_file.attachment.attach(
      io: tempfile,
      filename: name,
      content_type: file_type
    )
  ensure
    tempfile.close
    tempfile.unlink
  end
end
