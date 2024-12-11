class AuthController < ApplicationController
  # skip_before_action :verify_authenticity_token
  skip_before_action :check_authenticate_user!
  layout 'login'
  def login
    # redirect_to products_path if current_user
    if current_user
      @products = Product.includes(:image_attachment)
      render 'products/index', layout: 'application'
    end
  end

  def telegram_auth
    unless user_signed_in?
      data      = params.to_unsafe_h.except(:controller, :action)
      init_data = URI.decode_www_form(data["initData"]).to_h
      return redirect_to "https://t.me/#{settings[:tg_main_bot]}" if init_data.blank?

      tg_user = JSON.parse init_data["user"]
      user    = User.find_or_create_by_tg(tg_user)
      sign_in(user)
    end

    render json: { success: true, user: current_user } # head :ok
  end

  private

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac         = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, check_string)
    hmac == data["hash"]
  end
end
