module Admin
  class AnalyticsController < Admin::ApplicationController
    def index
      start_date, end_date, group_by = calculate_date_range_and_group_by(params[:period])
      revenue_data = Order.revenue_by_date(start_date, end_date, group_by).sort.to_h

      render json: {
        dates: revenue_data.keys,
        revenues: revenue_data.values
      }
    end

    private

    def calculate_date_range_and_group_by(period)
      case period
      when 'week'
        start_date = 4.weeks.ago.beginning_of_week
        end_date = Date.today.end_of_week
        group_by = 'YEARWEEK(orders.created_at)'
      when 'month'
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_month
        group_by = "DATE_FORMAT(orders.created_at, '%Y-%m')"
      else
        start_date = Date.today.prev_day(7)
        end_date = Date.today.end_of_month
        group_by = 'DATE(orders.created_at)'
      end
      [start_date, end_date, group_by]
    end
  end
end
