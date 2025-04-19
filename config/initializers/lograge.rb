Rails.application.configure do
  lograge_logger           = ActiveSupport::Logger.new("log/#{Rails.env}.log", 10, 50.megabytes)
  config.lograge.enabled   = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger    = lograge_logger
  config.lograge.custom_payload { |controller| { user_id: controller.current_user&.id } }
  config.lograge.custom_options = lambda do |event|
    payload = event.payload || {}
    result  = {
      timestamp: Time.current,
      level: payload[:level] || 'unknown',
      request_id: payload[:headers] && payload[:headers]['action_dispatch.request_id'],
      user_id: payload[:user_id],
      remote_ip: payload[:request]&.remote_ip
    }
    params = payload[:params]&.except('controller', 'action', '_method', 'authenticity_token')
    result[:params] = params if params.present?
    result
  end
end
