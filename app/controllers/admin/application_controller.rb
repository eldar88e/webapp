module Admin
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    layout 'admin'

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
  end
end