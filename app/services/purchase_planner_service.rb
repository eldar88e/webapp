class PurchasePlannerService
  STATISTICS_PERIOD = 1.year
  LEAD_TIME = Setting.fetch_value(:lead_time).to_i.days

  def initialize(product)
    @product = product
  end

  def avg_daily_consumption(period = STATISTICS_PERIOD)
    one_year_orders = OrderItem.where(product_id: @product.id, created_at: period.ago..Time.current)
    total = one_year_orders.sum(:quantity)
    total / (period / 1.day).to_f
  end

  def expected_finish_date
    return nil if avg_daily_consumption.zero?

    days_left = @product.stock_quantity / avg_daily_consumption
    Time.zone.today + days_left.round
  end

  def purchase_date(lead_time = LEAD_TIME)
    return nil unless expected_finish_date

    expected_finish_date - lead_time
  end
end
