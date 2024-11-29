require "openssl"

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :telegram_auth

  def telegram_auth
    Rails.logger.info request.body.read
    secret_key = OpenSSL::Digest::SHA256.digest(ENV['TELEGRAM_BOT_TOKEN'])
    data = params.to_unsafe_h.except(:controller, :action)

    binding.pry
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, check_string)

    if hmac == data['hash']
      user = User.find_or_create_by(tg_id: data['user']['id']) do |u|
        u.username = data['user']['username']
        u.first_name = data['user']['first_name']
        u.last_name = data['user']['last_name']
        u.photo_url = data['user']['photo_url']
      end

      # Логиним пользователя
      session[:user_id] = user.id

      render json: { success: true, user: user }
    else
      render json: { success: false, error: 'Invalid hash' }, status: :unauthorized
    end
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
