class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def limit_user_privileges(error, user)
    unless error.instance_of?(Telegram::Bot::Exceptions::ResponseError)
      Rails.logger.error("Telegram new sending error: #{error.message}")
      return ErrorMailer.send_error(error.message, error.full_message).deliver_later
    end

    if error.message.include?('chat not found')
      user.update(started: false)
    elsif error.message.include?('bot was blocked')
      user.update(is_blocked: true)
    end
  end
end
