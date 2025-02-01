Rails.application.configure do
  if Rails.env.production? && ENV['LOGSTASH_HOST'].present? && ENV['LOGSTASH_PORT'].present?
    logstash_logger = LogStashLogger.new(
      type: :udp,
      host: ENV['LOGSTASH_HOST'],
      port: ENV['LOGSTASH_PORT'].to_i,
      formatter: :json_lines,
      customize_event: lambda do |event|
        event['host'] = { name: Socket.gethostname }
        event['service'] = defined?(Sidekiq::CLI) ? 'sidekiq' : 'app' # ['app']
      end
    )

    logger = ActiveSupport::TaggedLogging.new(logstash_logger)

    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Logstash.new
    config.lograge.custom_options = lambda do |event|
      {
        remote_ip: event.payload[:request]&.remote_ip,
        process_id: Process.pid,
        request_id: event.payload[:headers]['action_dispatch.request_id'],
        request_body: event.payload[:params].except('controller', 'action', 'format')
      }
    end
    config.lograge.custom_payload { |controller| { user_id: controller.current_user.try(:id) } }
    config.lograge.logger = logstash_logger
  else
    file_logger = ActiveSupport::Logger.new(
      "log/#{Rails.env}.json.log",
      10, # Количество файлов для ротации (например, 10)
      20 * 1024 * 1024 # Максимальный размер файла (20 МБ)
    )

    file_logger.formatter = proc do |severity, timestamp, progname, msg|
      log_entry = {
        timestamp: timestamp,
        level: severity,
        message: msg,
        request_id: Thread.current[:request_id]
      }.to_json + "\n"
      log_entry
    end

    logger = ActiveSupport::TaggedLogging.new(file_logger)
  end

  config.logger = logger
  config.log_tags  = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
end
