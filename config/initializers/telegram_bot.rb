if Rails.env.production? || Rails.env.development?
  Rails.application.eager_load!
  Rails.logger.info 'Running TelegramBotWorker...'

  TelegramBotWorker.perform_async
end
