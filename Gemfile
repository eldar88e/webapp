source "https://rubygems.org"

ruby "3.3.3"
gem "rails", "~> 7.2.2"

gem "sprockets-rails"
gem "pg", "~> 1.5"
gem "puma", "~> 6.5"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "jbuilder"
gem "redis", "~> 5.2"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# gem "image_processing", "~> 1.2"
gem "dotenv"
gem "devise"

gem "pry"

group :development, :test do

  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem "brakeman", "~> 6.2", require: false
  gem "bullet"
  gem "web-console"
end

group :test do
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "shoulda-matchers"
end
