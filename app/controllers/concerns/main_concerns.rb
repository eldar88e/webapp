module MainConcerns
  extend ActiveSupport::Concern

  included do
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

  def settings
    @settings ||= Setting.all_cached
  end
end
