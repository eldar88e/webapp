source 'https://rubygems.org'

ruby '3.3.7'
gem 'rails', '~> 7.2.2'

gem 'bootsnap', require: false
gem 'jbuilder'
gem 'puma', '~> 6.6'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

gem 'pg', '~> 1.5'
gem 'redis', '~> 5.4'
gem 'vite_rails'

# gem 'aws-sdk-s3'
gem 'active_link_to'
gem 'ancestry'
gem 'devise'
gem 'dotenv'
gem 'i18n'
gem 'image_processing'
gem 'lograge'
gem 'logstash-logger'
# gem 'mongoid'
gem 'google-api-client', require: false
gem 'googleauth', require: false
gem 'pagy'
gem 'pundit'
gem 'ransack'
gem 'rollbar'
gem 'ruby-vips'
gem 'sidekiq', '~> 8.0'
# gem 'sidekiq-unique-jobs'
gem 'telegram-bot-ruby', require: false
gem 'valid_email2'
gem 'pry'

group :development, :test do
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'bullet' # , require: false unless defined?(Mongoid) for MongoDB
  gem 'letter_opener'
  gem 'sshkit'
  gem 'web-console'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
end
