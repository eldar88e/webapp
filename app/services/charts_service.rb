class ChartsService
  DATE_STARTED_PROJECT = Time.zone.local(2024, 1, 1).beginning_of_year
  KEY_TRANSFORMATIONS  = {
    nil => ->(key) { "#{I18n.t('date.abbr_day_names')[key.strftime('%w').to_i]}. #{key.day}" },
    'month' => ->(key) { "#{I18n.t('date.abbr_month_names')[key.month]} #{key.strftime('%-d')}" },
    'year' => ->(key) { I18n.t('date.abbr_month_names')[key.month] + " #{key.year} года" },
    'all' => ->(key) { "#{key.year} год" }
  }.freeze

  def initialize(period, per = nil)
    @period     = period
    @per        = form_per(per)
    @start_date = calculate_date_range
    @end_date   = Time.zone.today.end_of_day # TODO: переписать для диапазона с точным указанием даты через DatePicker
  end

  def orders
    orders = Order.count_order_with_status(@start_date, @end_date)

    { dates: orders[0].keys, orders: orders[0].values, total: orders[1] }
  end

  def revenue
    group_by = form_group_by('paid_at')
    payments = Order.revenue_by_date(@start_date, @end_date, group_by).sort.to_h
    payments = prepare_date_key(payments)

    { dates: payments.keys, revenues: payments.values }
  end

  def sold
    group_by = form_group_by('orders.paid_at')
    sold_data = OrderItem.total_quantity_sold(@start_date, @end_date, group_by).sort.to_h
    sold_data = prepare_date_key(sold_data)

    { dates: sold_data.keys, solds: sold_data.values }
  end

  def repeat
    User.repeat_order_rate(@start_date, @end_date)
  end

  def users
    group_by = form_group_by('created_at')
    users    = User.registered_count_grouped_by_period(@start_date, @end_date, group_by).sort.to_h
    users    = prepare_date_key(users)

    { dates: users.keys, users: users.values }
  end

  private

  def form_group_by(time_column)
    time_zone = "AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.name}'"
    {
      'year' => "DATE_TRUNC('year', #{time_column} #{time_zone})",
      'month' => "DATE_TRUNC('month', #{time_column} #{time_zone})",
      'week' => "DATE_TRUNC('week', #{time_column} #{time_zone})",
      'day' => "DATE_TRUNC('day', #{time_column} #{time_zone})"
    }[@per]
  end

  def form_per(per)
    case @period
    when 'month'
      %w[day week].include?(per) ? per : 'day'
    when 'year'
      %w[month week].include?(per) ? per : 'month'
    when 'all'
      %w[year month].include?(per) ? per : 'year'
    else
      'day'
    end
  end

  def populate_missing_dates(range)
    (@start_date.to_date..@end_date.to_date).index_with { 0 }.merge(range)
  end

  def prepare_date_key(range)
    range          = populate_missing_dates(range) if [nil, 'day'].include?(@per)
    transformation = KEY_TRANSFORMATIONS[@period] || KEY_TRANSFORMATIONS[nil]
    range.transform_keys(&transformation)
  end

  def calculate_date_range
    case @period
    when 'month'
      Time.zone.now.beginning_of_month
    when 'year'
      Time.zone.now.beginning_of_year
    when 'all'
      DATE_STARTED_PROJECT
    else
      # TODO: переписать для диапазона с точным указанием даты через DatePicker
      6.days.ago.beginning_of_day # this lint move to when 'week'
    end
  end
end
