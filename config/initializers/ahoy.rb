module Ahoy
  class Store < Ahoy::DatabaseStore
    def geocode(visit)
      db     = MaxMindDB.new(Rails.root.join('lib/data/GeoLite2-City.mmdb'))
      result = db.lookup(visit.ip)

      {
        country: result.country.name,
        region: result.subdivisions.first&.name,
        city: result.city.name,
        latitude: result.location.latitude,
        longitude: result.location.longitude
      }
    rescue StandardError => e
      Rails.logger.error "Ahoy geocoding failed: #{e.message}"
      {}
    end
  end
end

Ahoy.api = false

Ahoy.geocode = true
Ahoy.cookies = :none
