require 'caxlsx'

class SalesReportService
  STATUS_ORDER = :shipped

  def initialize(year = Time.current.year)
    @year = year
    @file_path = Rails.root.join('tmp', "sales_report_#{@year}.xlsx")
  end

  def self.call(year = Time.current.year)
    new(year).call
  end

  def call
    package = Axlsx::Package.new
    workbook = package.workbook

    styles = workbook.styles
    header = styles.add_style(b: true)
    # money  = styles.add_style(format_code: '#,##0.00')
    # total  = styles.add_style(b: true, format_code: '#,##0.00')

    data = sales_data

    workbook.add_worksheet(name: @year.to_s) do |sheet|
      sheet.add_row %w[Месяц Товар Количество Сумма], style: header
      add_rows(data, sheet)
    end

    package.serialize(@file_path)
    @file_path
  end

  private

  def add_rows(data, sheet)
    data.each do |month, items|
      month_total = 0
      items.each do |item|
        add_item(item, sheet, month)
        month_total += item.total_sum.to_f
      end

      sheet.add_row [month.strftime('%B %Y'), 'ИТОГО', '', month_total]
      sheet.add_row []
    end
  end

  def add_item(item, sheet, month)
    sheet.add_row [
      month.strftime('%B %Y'),
      item.name,
      item.total_qty.to_i,
      item.total_sum.to_f
    ]
  end

  def sales_data
    items_sql = OrderItem
                .joins(order: [], product: [])
                .where(orders: { status: STATUS_ORDER })
                .where(orders: { paid_at: year_range })
                .select(
                  "DATE_TRUNC('month', orders.paid_at) AS month",
                  'products.name AS name',
                  'SUM(order_items.quantity) AS total_qty',
                  'SUM(order_items.quantity * order_items.price) AS total_sum'
                )
                .group('month', 'products.name')

    delivery_price = Setting.fetch_value(:delivery_price).to_i

    delivery_sql = Order
                   .where(status: STATUS_ORDER)
                   .where(paid_at: year_range)
                   .where(has_delivery: true)
                   .select(
                     "DATE_TRUNC('month', orders.paid_at) AS month",
                     "'Доставка' AS name",
                     'COUNT(*) AS total_qty',
                     "COUNT(*) * #{delivery_price} AS total_sum"
                     )
                   .group('month')

    union_sql = "#{items_sql.to_sql} UNION ALL #{delivery_sql.to_sql}"

    OrderItem
      .from("(#{union_sql}) AS sales")
      .select('month, name, total_qty, total_sum')
      .order('month ASC, name ASC')
      .group_by(&:month)
  end

  def year_range
    Date.new(@year, 1, 1)..Date.new(@year, 12, 31).end_of_day
  end
end
