class ChartsService
  def initialize(period, users = nil)
    @start_date, @end_date, @group_by = calculate_date_range_and_group_by(period, users)
  end

  def orders
    orders = Order.count_order_with_status(@start_date, @end_date)

    { dates: orders[0].keys, orders: orders[0].values, total: orders[1] }
  end

  def revenue
    revenue_data = Order.revenue_by_date(@start_date, @end_date, @group_by).sort.to_h

    { dates: revenue_data.keys, revenues: revenue_data.values }
  end

  def sold
    sold_data = OrderItem.total_quantity_sold(@start_date, @end_date, @group_by).sort.to_h

    { dates: sold_data.keys, solds: sold_data.values }
  end

  def repeat
    User.repeat_order_rate(@start_date, @end_date)
  end

  def users
    users = User.registered_count_grouped_by_period(@start_date, @end_date, @group_by).sort.to_h

    { dates: users.keys, users: users.values }
  end

  private

  def calculate_date_range_and_group_by(period, users)
    column = users ? 'created_at' : 'orders.updated_at'
    case period
    when 'month'
      start_date = Time.zone.today.beginning_of_month
      end_date   = Time.zone.today.end_of_month
      group_by   = "DATE(#{column})"
    when 'year'
      start_date = Time.zone.today.beginning_of_year
      end_date   = Time.zone.today.end_of_day
      group_by   = "DATE_TRUNC('month', #{column})"
    when 'all'
      start_date = column.include?('order') ? Order.minimum(column) : User.minimum(column)
      end_date   = Time.zone.today.end_of_day
      group_by   = "DATE_TRUNC('year', #{column})"
    else
      start_date = 7.days.ago.beginning_of_day
      end_date   = Time.zone.today.end_of_day
      group_by   = "DATE(#{column})"
    end
    [start_date, end_date, group_by]
  end
end
