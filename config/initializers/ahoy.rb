module Ahoy
  class Store < Ahoy::DatabaseStore; end
end

Ahoy.api = false

Ahoy.geocode = true
Ahoy.cookies = :none
