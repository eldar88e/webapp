Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: 'lib/data/GeoLite2-City.mmdb'
  }
)
