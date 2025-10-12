class OrderStatisticsQuery
  STATUSES = %w[shipped overdue cancelled refunded].freeze

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

    def order_statuses(start_date, end_date, group_by)
      orders  = Order.where(updated_at: start_date..end_date, status: STATUSES)
      dates   = GroupDatesService.build_date_range(start_date, end_date, group_by)
      grouped = build_grouped_orders(orders, group_by)
      dates.index_with { |date| grouped[date] || STATUSES.index_with { 0 } }
    end

    private

    def build_grouped_orders(orders, group_by)
      group_method = GroupDatesService.group_by_period(group_by)
      orders.group_by { |o| o.updated_at.public_send(group_method) }.transform_values do |period_orders|
        status_counts = period_orders.group_by(&:status).transform_values(&:count) # .tally_by(&:status)
        STATUSES.index_with { |s| status_counts[s] || 0 }
      end
    end
  end
end
