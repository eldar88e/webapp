module ExchangeRate
  extend ActiveSupport::Concern

  def set_exchange_rate
    ExchangeRateSyncJob.perform_later(self.class.to_s, id)
  end
end
