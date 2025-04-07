class ConsumerSenderTgJob < ApplicationJob
  queue_as :default

  def perform(**args)
    args[:data][:file] = TgMediaFile.find_by(id: args[:data][:media_id])&.attachment unless args[:data][:tg_file_id]
    result = Tg::MediaSenderService.call(args[:msg], args[:id], args[:data])
    update_entities(args, result)
  end

  private

  def update_entities(args, result)
    user = User.find_by(tg_id: args[:id])
    return limit_user_privileges(result, user) unless result.instance_of?(Telegram::Bot::Types::Message)

    message   = Message.find(args[:msg_id])
    msg_attrs = { tg_msg_id: result.message_id }
    save_file_id(args, msg_attrs, message, result) if args[:data][:tg_file_id].blank? && args[:data][:file].present?
    message.update(msg_attrs)
    user.update(is_blocked: false, started: true)
  end

  def save_file_id(args, msg_attrs, message, result)
    media_file = TgMediaFile.find(args[:data][:media_id])
    file_id    = form_file_id(result, media_file)
    media_file.update(file_id: file_id)
    msg_attrs[:data] = message.data.merge(file_id: file_id)
  end

  def form_file_id(result, media_file)
    if media_file.image?
      result.photo.last.file_id
    elsif media_file.video?
      result.video.file_id
    end
  end
end
