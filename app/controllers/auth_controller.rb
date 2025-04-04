class AuthController < ApplicationController
  skip_before_action :check_authenticate_user!
  skip_before_action :check_started_user!, only: %i[telegram_auth error_register user_checker]
  before_action :set_btn_link, only: :login
  layout 'login'

  def login
    return unless current_user
    return redirect_to "/#{@btn_link}" if @btn_link.present?

    redirect_to products_path
    # available_products
    # render 'products/index', layout: 'application'
  end

  def telegram_auth
    data      = params.to_unsafe_h.except(:controller, :action)
    init_data = URI.decode_www_form(data['initData'].to_s).to_h
    return render_error_auth if init_data.blank? || init_data['user'].blank?

    sign_in_with_tg_id(init_data['user'])
    render json: { success: true } # user: current_user, params: init_data['start_param'] head :ok
  end

  def error_register
    UserCheckerJob.perform_later(current_user.id)
    render :error_register, layout: 'application'
  end

  def user_checker
    user = User.find_by(id: params[:user_id].to_i)
    if user.blank? || user.started.blank? || user.is_blocked.present?
      msg = "User #{params[:user_id]} not found or no started or banned bot!"
      Rails.logger.error msg
      render json: { error: msg }
    else
      render json: { started: user.started }
    end
  end

  private

  def render_error_auth
    msg = "Params 'initData' is empty or empty user!"
    Rails.logger.error msg
    render json: { error: msg }
  end

  def sign_in_with_tg_id(tg_user_object)
    tg_user = JSON.parse tg_user_object
    user    = User.find_or_create_by_tg(tg_user, false)
    update_tg_username(user, tg_user) # TODO: сделать через job возможно еще добавить атрибутов для обновления
    sign_in(user)
  end

  def update_tg_username(user, tg_user)
    user.update(photo_url: tg_user['photo_url']) # TODO: со временем убрать
    user.update(username: tg_user['username']) if user.username != tg_user['username']
  end

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac         = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), secret_key, check_string)
    hmac == data['hash']
  end

  def set_btn_link
    return unless params['tgWebAppStartParam'].present? && params['tgWebAppStartParam'].include?('url=')

    @btn_link = params['tgWebAppStartParam'].sub('url=', '').tr('_', '/') # TODO: возможно "_" убрать из url
  end
end
