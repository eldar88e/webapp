module Admin
  class ApplicationController < ActionController::Base
    include Pundit::Authorization
    before_action :authenticate_user!
    before_action :authorize_admin_access!
    helper_method :settings

    include Pagy::Backend
    layout 'admin'

    rescue_from Pundit::NotAuthorizedError, with: :redirect_to_telegram

    private

    def redirect_to_telegram
      redirect_to "https://t.me/#{settings[:tg_main_bot]}", allow_other_host: true
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

    def settings
      Setting.all_cached
    end
  end
end
