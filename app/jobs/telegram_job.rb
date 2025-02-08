class TelegramJob < ApplicationJob
  queue_as :default

  def perform(**args)
    if args[:method] == 'delete_msg'
      TelegramMsgDelService.remove(args[:id], args[:msg_id])
    else
      TelegramService.call(args[:msg], args[:id], **(args[:args] || {}))
    end
  end
end
