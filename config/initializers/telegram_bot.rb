Rails.application.config.after_initialize do
  if defined?(Sidekiq::CLI) && (Rails.env.production? || Rails.env.development?)
    Rails.logger.info 'Run TelegramBotWorker after initialize...'
    TelegramBotWorker.perform_async
  end
end

Signal.trap('TERM') do
  puts "\nShutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end

Signal.trap('INT') do
  puts "\nShutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end
