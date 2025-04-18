require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.year.to_i}, immutable" }

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' },
    namespace: 'cache',
    expires_in: 2.hours
  }

  if ENV.fetch('LOGSTASH_HOST', nil).present? && ENV.fetch('LOGSTASH_PORT', nil).present?
    logstash_logger = LogStashLogger.new(
      type: :udp,
      host: ENV.fetch('LOGSTASH_HOST'),
      port: ENV.fetch('LOGSTASH_PORT').to_i,
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
    # config.lograge.logger = logstash_logger
  else
    file_logger = ActiveSupport::Logger.new('log/production.log', 10, 50.megabytes)
    #
    # file_logger.formatter = proc do |severity, timestamp, _progname, msg|
    #   "#{{ timestamp: timestamp, level: severity, message: msg, request_id: Thread.current[:request_id] }.to_json}\n"
    # end
    #
    logger = ActiveSupport::TaggedLogging.new(file_logger)

    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new

    config.lograge.custom_payload { |controller| { user_id: controller.current_user&.id } }

    config.lograge.custom_options = lambda do |event|
      result = {
        time: Time.current,
        request_id: event.payload[:headers]['action_dispatch.request_id'],
        user_id: event.payload[:user_id],
        remote_ip: event.payload[:request]&.remote_ip
      }
      params = event.payload[:params].except('controller', 'action', '_method', 'authenticity_token')
      result[:params] = params if params.present?
      result
    end
  end

  config.logger    = logger
  # config.log_tags  = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV.fetch('HOST') }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.beget.com',
    port: 465,
    domain: ENV.fetch('HOST'),
    user_name: ENV.fetch('EMAIL_FROM'),
    password: ENV.fetch('EMAIL_PASSWORD'),
    authentication: 'login',
    ssl: true,
    tls: true,
    enable_starttls_auto: false
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [ENV.fetch('HOST', 'localhost'), 'miniapp']
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
