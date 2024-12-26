module Admin
  class AnalyticsController < Admin::ApplicationController
    ALLOWED_TYPES = %w[users orders revenue sold repeat].freeze

    def index
      type         = params[:type]
      users        = type == 'users'
      cache_expiry = 30.minutes
      cache_key    = "#{type}_#{params[:period]}"

      unless ALLOWED_TYPES.include?(type)
        return render json: { error: 'Invalid type parameter' }, status: :unprocessable_entity
      end


      cached_data  = Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
        ChartsService.new(params[:period], users).send(type.to_sym)
      end

      # cached_data = ChartsService.new(params[:period], users).send(type.to_sym)

      render json: cached_data
    end
  end
end
