require 'faraday'

class CurrencyRateService
  EXCHANGE_SERVER_URL = 'https://openexchangerates.org/api/latest.json'.freeze
  EXCHANGE_APP_ID     = ENV.fetch('EXCHANGE_APP_ID', nil)
  BASE_CURRENCY       = 'RUB'.freeze

  def initialize(currency, base_currency = nil)
    @currency      = currency.upcase
    @base_currency = base_currency&.upcase || BASE_CURRENCY
  end

  def self.call(currency, base_currency = nil)
    new(currency, base_currency).form_currency_rate
  end

  def form_currency_rate
    response = fetch_exchange_rate
    new_rate = parse_rate(response)
    (new_rate[@base_currency] / new_rate[@currency]).round(2)
  end

  private

  def fetch_exchange_rate
    connection = Faraday.new(url: EXCHANGE_SERVER_URL)
    response   = connection.get("?app_id=#{EXCHANGE_APP_ID}&symbols=#{@currency},#{@base_currency}")
    raise StandardError, 'Failed to fetch exchange rate data' unless response.success?

    response
  end

  def parse_rate(response)
    JSON.parse(response.body)['rates']
  end
end
