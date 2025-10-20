class AuthController < ApplicationController
  skip_before_action :check_authenticate_user!, only: %i[telegram] # login
  # layout 'login'

  # def login
  #   @btn_link = params[:btn_link]
  # end

  def telegram
    data      = params.to_unsafe_h.except(:controller, :action)
    init_data = URI.decode_www_form(data['initData'].to_s).to_h
    return render_error_auth if init_data.blank? || init_data['user'].blank?

    sign_in_with_tg_id(init_data['user'])
    render json: { success: true } # user: current_user, params: init_data['start_param'] head :ok
  end

  # def error_register
  #   UserCheckerJob.perform_later(current_user.id)
  #   render :error_register, layout: 'application'
  # end

  def user_checker
    if current_user.started.blank? || current_user.is_blocked.present?
      msg = "User #{current_user.id} not started or banned bot!"
      Rails.logger.warn msg
      render json: { error: msg }
    else
      render json: { started: current_user.started }
    end
  end

  private

  def render_error_auth
    msg = "Params 'initData' is empty or empty user!"
    Rails.logger.warn msg
    render json: { error: msg }
  end

  def sign_in_with_tg_id(tg_user_object)
    tg_user = JSON.parse tg_user_object
    user    = User.find_or_create_by_tg(tg_user, false)
    update_tg_username(user, tg_user)
    sign_in(user)
  end

  def update_tg_username(user, tg_user)
    user.update!(
      photo_url: tg_user['photo_url'],
      username: tg_user['username'],
      first_name_raw: tg_user['first_name'],
      last_name_raw: tg_user['last_name']
    )
  rescue StandardError => e
    Rails.logger.error "Failed to update user #{user.id}: #{e.message}"
  end

  def valid_telegram_data?(data, secret_key)
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    hmac         = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), secret_key, check_string)
    hmac == data['hash']
  end
end
