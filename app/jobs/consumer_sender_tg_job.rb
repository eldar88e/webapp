class ConsumerSenderTgJob < ApplicationJob
  queue_as :default

  def perform(**args)
    result = TelegramService.call(args[:msg], args[:id], **args[:markup])
    user   = User.find_by(tg_id: args[:id])
    return limit_user_privileges(result, user) unless result.instance_of?(Integer)

    user.update(is_blocked: false, started: true)
    add_msg_id(args[:msg_id], result) if args[:msg_id]
    # TODO: Реализовать отправку Картинок, видео, репост.
  end

  private

  def add_msg_id(msg_id, tg_msg_id)
    Message.find_by(id: msg_id)&.update(tg_msg_id: tg_msg_id)
  end
end
