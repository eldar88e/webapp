host = Rails.env.production? ? 'redis' : 'localhost'

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{host}:6379/2" }

  config.on(:startup) { puts 'Sidekiq server is running!' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{host}:6379/2" }
end
