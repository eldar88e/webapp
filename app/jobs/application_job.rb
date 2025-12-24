class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def limit_user_privileges(error, user, business = nil)
    if !error.instance_of?(Telegram::Bot::Exceptions::ResponseError)
      notify_email_admin(error, 'Telegram new sending error')
    elsif error.message.include?('chat not found')
      update_user({ started: false }, user, business)
    elsif error.message.include?('bot was blocked')
      update_user({ is_blocked: true }, user, business)
    else
      notify_email_admin(error, 'Telegram new sending type error')
    end
  end

  def notify_email_admin(error, msg)
    Rails.logger.error("#{msg}: #{error.message}")
    AdminMailer.send_error(error.message, error.full_message).deliver_later
  end

  def update_user(attrs, user, business)
    user.update(attrs)
    return if business.blank?

    msg = attrs[:started] == false ? 'не нажатия на старт!' : 'блокировки бота клиентом!'
    notify_admin(msg)
  end

  def notify_admin(message)
    msg = 'Клиенту не пришло бизнес сообщение по причине'
    TelegramService.call("#{msg} #{message}", Setting.fetch_value(:test_id))
  end

  class << self
    private

    def send_email_to_admin(exception)
      subject = 'Task execution error'
      AdminMailer.send_error(exception, '', subject).deliver_now
    end
  end
end
