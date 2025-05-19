class TgFileDownloaderJob < ApplicationJob
  queue_as :default

  def perform(**args)
    response = nil
    Telegram::Bot::Client.run(Setting.fetch_value(:tg_token)) do |bot|
      response = bot.api.get_file(file_id: args[:file_id])
    end

    return if response.blank? && args[:msg].blank?

    user = User.find_by(tg_id: args[:tg_id])
    return if user.blank?

    file_path = response.present? ? response.file_path : nil
    file_url  = "https://api.telegram.org/file/bot#{Setting.fetch_value(:tg_token)}/#{file_path}"
    tempfile  = URI.open(file_url)
    file_type = Marcel::MimeType.for(tempfile)
    name      = file_path.split('/')&.last
    file_hash = Digest::MD5.hexdigest(tempfile.read)

    tg_file = TgMediaFile.find_or_create_by!(file_hash: file_hash) do |media|
      media.file_id   = args[:file_id]
      media.file_hash = file_hash
      media.file_type = file_type
      media.original_filename = name
      media.attachment.attach(io: tempfile, filename: name, content_type: file_type)
      media.save
    end
    user.messages.create(
      text: args[:msg], tg_msg_id: args[:msg_id],
      data: { tg_file_id: tg_file.file_id, media_id: tg_file.id }
    )
  end
end
