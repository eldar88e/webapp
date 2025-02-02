class TelegramJob < ApplicationJob
  queue_as :default

  def perform(**args)
    if args[:method] == 'delete_msg'
      TelegramService.send(args[:method].to_sym, '', args[:id], args[:msg_id])
    else
      TelegramService.send(args[:method].to_sym, args[:msg], args[:id], **(args[:args] || {}))
    end
  end
end
