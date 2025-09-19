class PurchasePlannerService
  def initialize(product, start_date = nil, end_date = nil)
    @lead_time  = Setting.fetch_value(:lead_time).to_i.days
    @product    = product
    @start_date = start_date || OrderItem.order(created_at: :asc).first.created_at
    @end_date   = end_date || Time.current
  end

  def avg_daily_consumption
    total = OrderItem.joins(:order)
                     .where(product_id: @product.id, orders: { status: :shipped, shipped_at: @start_date..@end_date })
                     .sum(:quantity)
    total / (@end_date.to_date - @start_date.to_date).to_f
  end

  def expected_finish_date
    return if avg_daily_consumption.zero?

    days_left = @product.stock_quantity / avg_daily_consumption
    Time.current + days_left.round.days
  end

  def purchase_date(lead_time = nil)
    return unless expected_finish_date

    expected_finish_date - (lead_time || @lead_time)
  end
end
