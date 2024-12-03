class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def telegram_auth
    puts "=" * 80
    puts cookies.to_hash
    puts current_user
    puts "+" * 80

    unless user_signed_in?
      data = params.to_unsafe_h.except(:controller, :action)

      puts "=" * 80
      puts data
      puts "+" * 80

      init_data = URI.decode_www_form(data["initData"]).to_h
      return render json: { error: true, msg: "App for Telegram!" } if init_data.blank?

      tg_user   = JSON.parse init_data["user"]
      user      = User.find_or_create_by(tg_id: tg_user["id"]) do |u|
        u.username   = tg_user["username"]
        u.first_name = tg_user["first_name"]
        u.last_name  = tg_user["last_name"]
        u.full_name  = "#{tg_user["first_name"]} #{tg_user["last_name"]}"
        u.photo_url  = tg_user["photo_url"]
        u.email      = generate_email(tg_user["id"])
        u.password   = Devise.friendly_token[0, 20]
      end
      sign_in(user)
    end

    render head :ok # json: { success: true, user: current_user }
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
