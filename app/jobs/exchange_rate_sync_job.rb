class ExchangeRateSyncJob < ApplicationJob
  queue_as :default

  def perform(entity, id, currency = 'try')
    rate = fetch_exchange_rate(currency)
    Setting.sync_currency_rate(rate)
    return if entity.nil? || id.nil?

    model = entity.constantize
    # rubocop:disable Rails/SkipsModelValidations
    model.find_by(id: id)&.update_columns(exchange_rate: rate)
    # rubocop:enable Rails/SkipsModelValidations
    nil
  end

  private

  def fetch_exchange_rate(currency)
    CurrencyRateService.call(currency)
  rescue StandardError => e
    setting = Setting.find_by(variable: currency)
    msg     = "Error: #{e.message}.\n\nDate last updated exchange rate: #{setting.updated_at}"
    Rails.logger.error msg
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
    setting.value.to_f
  end
end
