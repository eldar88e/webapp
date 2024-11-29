require "openssl"

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :telegram_auth

  def telegram_auth
    data = params.to_unsafe_h.except(:controller, :action)
    user = User.find_or_create_by(tg_id: data['user']['id']) do |u|
      u.username   = data['user']['username']
      u.first_name = data['user']['first_name']
      u.last_name  = data['user']['last_name']
      u.photo_url  = data['user']['photo_url']
      u.email      = generate_email(data['user']['id'])
      u.password   = Devise.friendly_token[0, 20]
    end

    sign_in(user)
    render json: { success: true, user: user }
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
