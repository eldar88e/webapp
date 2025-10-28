module Tg
  class WebAppAuth
    MAX_AGE = 5.minutes

    def initialize(init_data, bot_token)
      @init_data = init_data.to_s
      @bot_token = bot_token
    end

    def valid?
      return false if parsed_data.blank?

      data_check_string = build_data_check_string
      secret_key        = OpenSSL::HMAC.digest('SHA256', 'WebAppData', @bot_token)
      calculated_hash   = OpenSSL::HMAC.hexdigest('SHA256', secret_key, data_check_string)
      auth_time         = Time.at(parsed_data['auth_date'].to_i).utc

      secure_compare?(calculated_hash, parsed_data['hash']) && (auth_time > MAX_AGE.ago.utc)
    end

    def user
      JSON.parse(parsed_data['user'])
    end

    private

    def secure_compare?(calculated_hash, parsed_hash)
      ActiveSupport::SecurityUtils.secure_compare(calculated_hash, parsed_hash)
    end

    def parsed_data
      @parsed_data ||= URI.decode_www_form(@init_data).to_h
    end

    def build_data_check_string
      parsed_data.except('hash').sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    end
  end
end
