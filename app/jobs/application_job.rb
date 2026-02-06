class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def limit_user_privileges(error, user, business = nil)
    Tg::ErrorHandlerService.call(error: error, user: user, business: business)
  end

  class << self
    private

    def send_email_to_admin(exception)
      subject = 'Task execution error'
      AdminMailer.send_error(exception, '', subject).deliver_now
    end
  end
end
