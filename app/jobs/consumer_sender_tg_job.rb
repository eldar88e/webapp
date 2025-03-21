class ConsumerSenderTgJob < ApplicationJob
  queue_as :default

  def perform(**args)
    result = TelegramService.call(args[:msg], args[:id], **args)
    unless result.instance_of?(Integer)
      user   = User.find_by(tg_id: result[:id])
      return limit_user_privileges(error, user)
    end

    add_msg_id(args, result) if args[:msg_id]
  end

  private

  def add_msg_id(args, id)
    Message.find(args[:msg_id])&.update(tg_msg_id: id)
  end
end
