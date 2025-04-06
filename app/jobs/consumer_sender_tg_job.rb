class ConsumerSenderTgJob < ApplicationJob
  queue_as :default

  def perform(**args)
    data = { type: args[:type], markup: args[:markup] }
    form_file_info(data, args)
    result = Tg::MediaSenderService.call(args[:msg], args[:id], data)
    user   = User.find_by(tg_id: args[:id])
    return limit_user_privileges(result, user) unless result.instance_of?(Telegram::Bot::Types::Message)

    update_entities(args, result, user)
  end

  private

  def form_file_info(data, args)
    if args[:tg_file_id]
      data[:file_id] = args[:tg_file_id]
    else
      data[:file] = TgMediaFile.find_by(id: args[:media_id])&.attachment
    end
  end

  def update_entities(args, result, user)
    message   = Message.find(args[:msg_id])
    msg_attrs = { tg_msg_id: result.message_id }
    save_file_id(args, msg_attrs, message, result) if args[:tg_file_id].blank? && args[:file].present?
    message.update(msg_attrs)
    user.update(is_blocked: false, started: true)
  end

  def save_file_id(args, msg_attrs, message, result)
    media_file = TgMediaFile.find(args[:media_id])
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
