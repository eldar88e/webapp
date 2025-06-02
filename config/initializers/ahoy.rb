module Ahoy
  class Store < Ahoy::DatabaseStore; end
end

Ahoy.api = false
Ahoy.cookies = :none

if Rails.env.local?
  Ahoy.server_side_visits = false
  Ahoy.exclude_method = ->(*) { true }
else
  Ahoy.geocode = true
end
