class ExchangeRateUpdaterJob < ApplicationJob
  retry_on StandardError, wait: 10.minutes, attempts: 2 do |_job, exception|
    send_email_to_admin exception.message
  end

  def perform(currency = 'try')
    rate = CurrencyRateService.call(currency)
    Setting.sync_currency_rate(rate)
    rate
  end

  private

  def self.send_email_to_admin(exception)
    subject = 'Task execution error'
    AdminMailer.notify_failure(exception, subject).deliver_now
  end
end
