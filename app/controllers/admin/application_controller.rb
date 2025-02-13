module Admin
  class ApplicationController < ActionController::Base
    include Pundit::Authorization

    before_action :authenticate_user!
    before_action :authorize_admin_access!

    include Pagy::Backend
    layout 'admin'

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      # flash[:alert] = "У вас нет доступа к этой странице."
      redirect_to "https://t.me/#{Setting.fetch_value(:tg_main_bot)}", allow_other_host: true
    end

    def authorize_admin_access!
      authorize %i[admin base], :admin_access?
    end

    def error_notice(msg, status = :unprocessable_entity)
      render turbo_stream: send_notice(msg, 'danger'), status:
    end

    def success_notice(msg)
      send_notice(msg, 'success')
    end

    def send_notice(msg, key)
      turbo_stream.append(:notices, partial: '/notices/notice', locals: { notices: msg, key: })
    end
  end
end
