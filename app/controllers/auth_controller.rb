class AuthController < ApplicationController
  skip_before_action :check_authenticate_user!
  layout 'login'
  def login
    return unless current_user
    if params['tgWebAppStartParam'].present? && params['tgWebAppStartParam'].include?('url=')
      return redirect_to "/#{params['tgWebAppStartParam'].sub('url=', '').tr('_', '/')}"
    end

    available_products
    render 'products/index', layout: 'application' # redirect_to products_path if current_user
  end

  def telegram_auth
    data = params.to_unsafe_h.except(:controller, :action)
    Rails.logger.error "Params ['initData'] is empty or nil." if data['initData'].blank?
    init_data = URI.decode_www_form(data['initData']).to_h
    return redirect_to_telegram if init_data.blank?

    tg_user = JSON.parse init_data['user']
    user    = User.find_or_create_by_tg(tg_user)
    sign_in(user)

    render json: { success: true, user: current_user, params: init_data['start_param'] } # head :ok
  end

  private

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac         = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), secret_key, check_string)
    hmac == data['hash']
  end
end
