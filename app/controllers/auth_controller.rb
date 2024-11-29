require "openssl"

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :telegram_auth

  def telegram_auth
    puts request.body.read
  end

  private

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, check_string)
    hmac == data["hash"]
  end

  def generate_email(telegram_id)
    "telegram_user_#{telegram_id}@example.com"
  end
end
