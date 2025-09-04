require "sidekiq-unique-jobs"

url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1').gsub('/1', '/2')

Sidekiq.configure_server do |config|
  config.redis = { url: url } # driver: :hiredis
  config.on(:startup) { Rails.logger.info 'Sidekiq server is running!' }
  config.logger = Rails.logger if Rails.env.production?

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: url }
  config.logger = Rails.logger if Rails.env.production?

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
