class AuthController < ApplicationController
  skip_before_action :check_authenticate_user!
  skip_before_action :check_started_user!, only: %i[telegram_auth error_register user_checker]
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
    init_data = URI.decode_www_form(data['initData'].to_s).to_h
    # redirect_to_telegram
    Rails.logger.error "Params ['initData'] is empty or nil." if init_data.blank? || init_data['user'].blank?
    return render json: { error: 'Not valid user data!' } if init_data.blank? || init_data['user'].blank?

    sign_in_with_tg_id(init_data['user'])
    render json: { success: true } # user: current_user, params: init_data['start_param'] head :ok
  end

  def error_register
    UserCheckerJob.perform_later(current_user.id)
    render :error_register, layout: 'application'
  end

  def user_checker
    user = User.find(params[:user_id])
    render json: { started: user.started }
  end

  private

  def sign_in_with_tg_id(tg_user_object)
    tg_user = JSON.parse tg_user_object
    user    = User.find_or_create_by_tg(tg_user)
    update_tg_username(user, tg_user)
    sign_in(user)
  end

  def update_tg_username(user, tg_user)
    return if user.username == tg_user['username']

    user.update(username: tg_user['username'])
    msg = "User #{user.id} updated username #{user.username}"
    Rails.logger.info msg
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac         = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), secret_key, check_string)
    hmac == data['hash']
  end
end
