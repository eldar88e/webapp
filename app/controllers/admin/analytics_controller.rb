module Admin
  class AnalyticsController < Admin::ApplicationController
    def index
      cache_key    = "#{params[:type]}_#{params[:period]}_"
      cache_expiry = 1.hour

      cached_data = Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
        # ChartsService.new(params[:period]).send(params[:type].to_sym)
      end

      cached_data = ChartsService.new(params[:period]).send(params[:type].to_sym)

      render json: cached_data
    end
  end
end
