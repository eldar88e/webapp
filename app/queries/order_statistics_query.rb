class OrderStatisticsQuery
  class << self
    def revenue_by_date(start_date, end_date, group_by)
      Order.where(paid_at: start_date..end_date)
           .where.not(status: :canceled)
           .group(group_by)
           .sum(:total_amount)
    end

    def count_orders_with_status(start_date, end_date)
      total_orders = Order.where(updated_at: start_date..end_date).count
      result = Order.statuses.keys.each_with_object({}) do |status, hash|
        status_count = Order.where(status: Order.statuses[status])
                            .where(updated_at: start_date..end_date)
                            .count
        next if status_count.zero?

        hash[status.to_sym] = status_count
      end
      [result, total_orders]
    end

    def order_statuses(start_date, end_date)
      orders       = Order.where(updated_at: start_date..end_date)
      all_statuses = Order.statuses.keys
      date_range   = (start_date.to_date..end_date.to_date).to_a
      grouped      = build_grouped_orders(orders, all_statuses)
      date_range.index_with { |date| grouped[date] || all_statuses.index_with { 0 } }
    end

    def build_grouped_orders(orders, all_statuses)
      orders.group_by { |o| o.updated_at.to_date }.transform_values do |day_orders|
        counts = day_orders.group_by(&:status).transform_values(&:count)
        all_statuses.index_with { |s| counts[s] || 0 }
      end
    end
  end
end
