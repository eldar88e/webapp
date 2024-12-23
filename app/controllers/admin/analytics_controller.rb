module Admin
  class AnalyticsController < Admin::ApplicationController
    def index
      cache_key    = "revenue_json_#{params[:period]}"
      cache_expiry = 1.hour

      cached_data = Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
        start_date, end_date, group_by = calculate_date_range_and_group_by(params[:period])
        revenue_data = Order.revenue_by_date(start_date, end_date, group_by).sort.to_h

        {
          dates: revenue_data.keys,
          revenues: revenue_data.values
        }
      end

      render json: cached_data
    end

    private

    def calculate_date_range_and_group_by(period)
      case period
      when 'week'
        start_date = 4.weeks.ago.beginning_of_week
        end_date = Date.today.end_of_week
        group_by = "DATE_TRUNC('week', orders.updated_at)"
      when 'month'
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_month
        group_by = "DATE_FORMAT(orders.updated_at, '%Y-%m')"
      else
        start_date = 7.days.ago.beginning_of_day
        end_date = Date.today.end_of_month
        group_by = 'DATE(orders.updated_at)'
      end
      [start_date, end_date, group_by]
    end
  end
end
