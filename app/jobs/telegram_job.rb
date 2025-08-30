class TelegramJob < ApplicationJob
  queue_as :telegram_notice

  def perform(**args)
    if args[:method] == 'delete_msg'
      TelegramMsgDelService.remove(args[:id], args[:msg_id])
    else
      TelegramService.call(args[:msg], args[:id], **args)
    end
  end
end
