require 'faraday'

module Admin
  class RollbarService
    API_ENDPOINT = 'https://api.rollbar.com'.freeze
    DEFAULT_TOKEN = ENV.fetch('ROLLBAR_READ_TOKEN', nil)

    def initialize(token = DEFAULT_TOKEN)
      @token = token
      @conn  = Faraday.new(url: API_ENDPOINT) do |f|
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end

    def items
      resp = @conn.get('/api/1/items', {}, { 'X-Rollbar-Access-Token' => @token })
      raise "Failed to fetch items: #{resp.body&.dig('message')}" unless resp.success?

      resp.body.dig('result', 'items') || []
    end

    def instances(item_id, limit: 100)
      resp = @conn.get("/api/1/item/#{item_id}/instances", { access_token: @token, limit: limit })
      raise "Failed to fetch instances: #{resp.body}" unless resp.success?

      resp.body.dig('result', 'instances') || []
    end
  end
end
