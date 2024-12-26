module Admin
  class AnalyticsController < Admin::ApplicationController
    def index
      cache_key    = "#{params[:type]}_#{params[:period]}"
      cache_expiry = 1.hour
      users        = params[:type] == 'users'

      cached_data  = Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
        # ChartsService.new(params[:period], users).send(params[:type].to_sym) TODO: использовать кэш
      end

      cached_data = ChartsService.new(params[:period], users).send(params[:type].to_sym)

      render json: cached_data
    end
  end
end
