module MainConcerns
  extend ActiveSupport::Concern

  included do
    before_action :append_user_to_lograge

    helper_method :settings
  end

  def redirect_to_telegram
    redirect_to "https://t.me/#{settings[:tg_main_bot]}", allow_other_host: true
  end

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

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def settings
    @settings_ ||= Setting.all_cached
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def append_user_to_lograge
    request.env['lograge.user_id'] = current_user&.id
  end
end
