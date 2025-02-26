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
  end
end
