host = Rails.env.production? ? 'redis' : 'localhost'

sidekiq_logstash_logger = LogStashLogger.new(
  type: :udp,
  host: ENV['LOGSTASH_HOST'],
  port: ENV['LOGSTASH_PORT'].to_i,
  formatter: :json_lines,
  customize_event: lambda do |event|
    event['host'] = { name: Socket.gethostname }
    event['service'] = ['sidekiq']
  end
)

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{host}:6379/2" }

  config.on(:startup) { puts 'Sidekiq server is running!' }
  # config.logger = sidekiq_logstash_logger
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{host}:6379/2" }
end
