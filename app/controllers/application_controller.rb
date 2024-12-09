class ApplicationController < ActionController::Base
  before_action :authenticate_dev!
  before_action :check_authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  private

  def error_notice(msg, status = :unprocessable_entity)
    render turbo_stream: send_notice(msg, 'danger'), status:
  end

  def success_notice(msg)
    send_notice(msg, 'success')
  end

  def send_notice(msg, key)
    turbo_stream.append(:notices, partial: '/notices/notice', locals: { notices: msg, key: })
  end

  def check_authenticate_user!
    unless current_user
      redirect_to 'https://t.me/atominexbot', allow_other_host: true
    end
  end

  def authenticate_dev!
    return if current_user || !Rails.env.development?

    sign_in(User.first)
    Rails.logger.info "Current user: #{current_user.email} for development!"
  end
end
