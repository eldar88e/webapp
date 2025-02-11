return if Rails.env.test?

Rails.application.config.after_initialize do
  if defined?(Sidekiq::CLI) && (Rails.env.production? || Rails.env.development?)
    Rails.logger.info 'Run TelegramBotWorker after initialize...'
    TelegramBotWorker.perform_async if Rails.env.production?
  end
end

Signal.trap('TERM') do
  bot = Rails.application.config.telegram_bot
  return if bot.nil?

  puts "\nShutting down bot..."
  bot.stop
  exit
end

Signal.trap('INT') do
  bot = Rails.application.config.telegram_bot
  return if bot.nil?

  puts "\nShutting down bot..."
  bot.stop
  exit
end
