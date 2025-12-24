module Admin
  class AnalyticsController < Admin::ApplicationController
    ANALYTICS_CACHE_TIME = 10.minutes

    def index
      if ChartsService.method_defined?(params[:type].to_sym, false)
        render json: process_cache(params[:type])
      else
        render json: { error: 'Invalid type parameter' }, status: :unprocessable_content
      end
    end

    private

    def process_cache(type)
      cache_key   = "#{type}_#{params[:period]}"
      cached_data = Rails.cache.fetch(cache_key, expires_in: ANALYTICS_CACHE_TIME) do
        ChartsService.new(params[:period]).send(type)
      end
      Rails.cache.delete(cache_key) if cached_data.nil?
      cached_data
    end
  end
end
