url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1').gsub('/1', '/2')

Sidekiq.configure_server do |config|
  config.redis = { url: url }
  config.on(:startup) { puts 'Sidekiq server is running!' }
  config.logger = Rails.logger if Rails.env.production?
end

Sidekiq.configure_client do |config|
  config.redis = { url: url }
  config.logger = Rails.logger if Rails.env.production?
end
