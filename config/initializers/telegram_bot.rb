if Rails.env.production? || Rails.env.development?
  Rails.logger.info 'Running TelegramBotWorker...'

  TelegramBotWorker.perform_async
end
