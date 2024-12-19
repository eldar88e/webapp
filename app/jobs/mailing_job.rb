class MailingJob < ApplicationJob
  queue_as :default
  MARKUP = 'mailing'.freeze

  def perform(**args)
    filter  = args[:filter] # :ordered no_ordered
    message = args[:message]
    clients =
      if filter == :ordered
        User.joins(:orders).where(orders: :ordered).distinct
      else
        User.joins(:orders).where.not(orders: :ordered).distinct
      end
    clients.each do |client|
      TelegramService.call(message, client.id, markup: MARKUP)
    end
  end
end
