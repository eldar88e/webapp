class StatisticsService
  ORDER_STATUS_BUY = :shipped

  def initialize(products, start_date = nil, end_date = nil)
    @start_date = start_date || OrderItem.order(created_at: :asc).first.created_at
    @end_date = end_date || Time.current
    @products = products
    @lead_time = Setting.fetch_value(:lead_time).to_i
    @strategy_days = Setting.fetch_value(:strategy_days).to_i
  end

  def self.call(products, start_date = nil, end_date = nil)
    new(products, start_date, end_date).process
  end

  def process
    result = @products.filter_map do |product|
      quantity_in_way = quantity_in_way(product)
      next if product.stock_quantity.zero? && quantity_in_way.zero?

      exchange_rate = last_purchase_item(product)&.purchase&.exchange_rate
      source_price_tl = form_source_price(product)
      source_price_ru = source_price_tl * exchange_rate
      avg_daily_consumption = form_planer_statistics(product)
      sales = count_sales(product)
      strategy_stock = (avg_daily_consumption * @strategy_days).round
      deficit = (product.stock_quantity + quantity_in_way - (avg_daily_consumption * @lead_time) - strategy_stock).round
      net_profit_period = (product.price - source_price_ru - expenses) * sales

      {
        id: product.id,
        image: product.image,
        name: product.name.tr(' ', "\u00A0"),
        price: form_price(product.price),
        avg_sale_price: form_price(avg_sale_price(product)),
        source_price_tl: form_price(source_price_tl, '₺'),
        source_price: form_price(source_price_ru),
        expenses_percent: (expenses * 100 / product.price).round,
        markup_percent: ((product.price - source_price_ru) * 100 / source_price_ru).round,
        stock_quantity: product.stock_quantity,
        quantity_in_way: quantity_in_way,
        money_in_product: (product.stock_quantity + quantity_in_way) * (expenses + source_price_ru),
        net_profit: form_price(product.price - source_price_ru - expenses),
        margin_period: ((net_profit_period / sales) * 100 / source_price_ru).round,
        net_profit_period: net_profit_period,
        net_profit_period_expenses: (product.price - source_price_ru) * sales,
        sales: sales,
        expenses: expenses,
        expenses_period: form_price(expenses * sales),
        deficit: deficit,
        strategy_stock: strategy_stock,
        days_of_stock: days_of_stock(product, avg_daily_consumption, quantity_in_way),
        rop: ((avg_daily_consumption * @lead_time) + strategy_stock).round,
        avg_daily_consumption: avg_daily_consumption
      }
    end

    sum_bonus = form_sum_bonus

    {
      products: result,
      money_in_product_sum: result.sum { |item| item[:money_in_product] },
      net_profit_sum: result.sum { |item| item[:net_profit_period].to_i } + sum_bonus,
      sum_bonus: sum_bonus
    }
  end

  private

  def form_sum_bonus
    orders_period = Order.includes(:bonus_logs).where(status: ORDER_STATUS_BUY, shipped_at: @start_date..@end_date)
    orders_period.sum do |order|
      last_bonus = order.bonus_logs.max_by(&:created_at)&.bonus_amount.to_i
      last_bonus.negative? ? last_bonus : 0
    end
  end

  def quantity_in_way(product)
    last_purchase_item(product, :shipped)&.quantity || 0
  end

  def form_price(price, currency = '₽')
    int = price.to_i
    formatted = int.to_s.reverse.scan(/\d{1,3}/).join("\u00A0").reverse
    "#{formatted}\u00A0#{currency}"
  end

  def expenses
    @expenses ||= Setting.fetch_value(:expenses).to_i
  end

  def last_purchase_item(product, status = nil)
    status ||= :stocked
    last_purchase(product, status)&.purchase_items&.find { |item| item.product_id == product.id }
  end

  def last_purchase(product, status)
    Rails.cache.fetch("last_purchase_#{product.id}_#{status}", expires_in: 1.hour) do
      Purchase.includes(:purchase_items).where(status: status)
              .where(purchase_items: { product_id: product.id })
              .order(created_at: :desc)
              .first
    end
  end

  def form_source_price(product)
    last_purchase_item(product)&.unit_cost
  end

  def form_planer_statistics(product)
    total = count_sales(product)
    (total / (@end_date.to_date - @start_date.to_date).to_f).round(2)
  end

  def order_items(product)
    OrderItem
      .joins(:order)
      .where(product_id: product.id, orders: { status: :shipped, shipped_at: @start_date..@end_date })
  end

  def avg_sale_price(product)
    order_items(product).average(:price)&.to_f || 0
  end

  def count_sales(product)
    order_items(product).sum(:quantity)
  end

  def days_of_stock(product, avg_daily_consumption, quantity_in_way)
    return 0 if avg_daily_consumption.zero?

    ((product.stock_quantity + quantity_in_way) / avg_daily_consumption).round
  end
end
