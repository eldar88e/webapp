if Rails.env.production?
  file_logger = ActiveSupport::Logger.new("log/#{Rails.env}.log", 10, 50.megabytes)
  file_logger.level = Logger::INFO
  file_logger.formatter = proc do |severity, _timestamp, progname, message|
    result = {
      timestamp: Time.current,
      level: severity,
      progname: progname || 'rails',
      message: message
    }
    if defined?(Sidekiq::CLI)
      result[:progname] = 'sidekiq'
      if message.is_a?(String)
        msg = message.dup
        msg.delete_prefix!('[ActiveJob] ')
        job_name = msg[/\[([\w|:]+Job)\]/, 1]
        msg.gsub!(job_name, '') if job_name.present?
        result[:job_name] = job_name if job_name.present?
        job_id = msg[/\[(\w+-\w+-\w+-\w+-\w+)\]/, 1]
        msg.gsub!(job_id, '') if job_id.present?
        result[:job_id] = job_id if job_id.present?
        result[:message] = msg.gsub(/\[\]|\(Job ID: \)/, '').strip.squeeze(' ')
      end
    end
    "#{result.to_json}\n"
  end

  # Rails.logger = ActiveSupport::TaggedLogging.new(file_logger)

  if defined?(Rails::Console)
    base_logger = ActiveSupport::Logger.new($stdout)
    logger      = ActiveSupport::BroadcastLogger.new(base_logger)
    logger.broadcast_to(file_logger)
  else
    logger = file_logger
  end

  Rails.logger = ActiveSupport::TaggedLogging.new(logger)
end
