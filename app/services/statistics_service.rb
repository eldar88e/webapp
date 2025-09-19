class StatisticsService
  def initialize(products, start_date = nil, end_date = nil)
    @start_date = start_date || OrderItem.order(created_at: :asc).first.created_at
    @end_date = end_date || Time.current
    @products = products
    @default_exchange_rate = Setting.fetch_value(:try).to_f
  end

  def self.call(products)
    new(products).process
  end

  def process
    @products.filter_map do |product|
      quantity_in_way = quantity_in_way(product)
      next if product.stock_quantity.zero? && quantity_in_way.zero?

      exchange_rate = last_purchase_item(product)&.purchase&.exchange_rate || @default_exchange_rate
      source_price_ru = form_source_price(product) * exchange_rate
      planer_statistics = form_planer_statistics(product)

      {
        id: product.id,
        image: product.image,
        name: product.name.tr(' ', "\u00A0"),
        price: form_price(product.price),
        avg_sale_price: form_price(avg_sale_price(product)),
        source_price_tl: form_price(form_source_price(product), '₺'),
        source_price: form_price(source_price_ru),
        expenses_percent: (expenses * 100 / product.price).round,
        markup_percent: ((product.price - source_price_ru) * 100 / source_price_ru).round,
        stock_quantity: product.stock_quantity,
        quantity_in_way: quantity_in_way,
        money_in_product: form_price((product.stock_quantity + quantity_in_way) * (expenses + source_price_ru)),
        net_profit: form_price(product.price - source_price_ru - expenses),
        sales: count_sales(product),
        expenses: expenses
      }.merge(planer_statistics)
    end
  end

  private

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
    last_purchase_item(product)&.unit_cost || 1 # TODO: remove hardcoded value
  end

  def form_planer_statistics(product)
    planer = PurchasePlannerService.new(product, @start_date, @end_date)

    {
      avg_daily_consumption: planer.avg_daily_consumption.round(2),
      expected_finish_date: planer.expected_finish_date,
      purchase_date: planer.purchase_date
    }
  end

  def count_sales(product)
    OrderItem
      .joins(:order)
      .where(product_id: product.id, orders: { status: :shipped, shipped_at: @start_date..@end_date })
      .sum(:quantity)
  end

  def avg_sale_price(product)
    OrderItem
      .joins(:order)
      .where(product_id: product.id, orders: { status: :shipped, shipped_at: @start_date..@end_date })
      .average(:price)
      &.to_f || 0
  end
end
