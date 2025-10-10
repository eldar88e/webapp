return if Rails.env.test?

Rails.application.config.after_initialize do
  if defined?(Sidekiq::CLI) && (ENV['SIDEKIQ_QUEUE'] == 'telegram_bot')

    Rails.logger.info 'Run TelegramBotWorker after initialize...'
    TelegramBotWorker.perform_async # if Rails.env.production?
  end
end

%w[TERM INT].each do |signal|
  Signal.trap(signal) do
    bot = Rails.application.config.telegram_bot
    # return if bot.nil?
    Rails.logger.info "\nShutting down bot..."
    bot&.stop
    # exit
  rescue StandardError => e
    Rails.logger.error "Error during bot shutdown: #{e.message}"
  end
end
