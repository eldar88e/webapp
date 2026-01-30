class ExportOrderService < GoogleSheetsService
  LAST_COLUMN = 'K'.freeze

  def initialize(order)
    super
    @order     = order
    @list_name = Setting.fetch_value(:google_list_orders).freeze
  end

  def export_order_items_to_sheets
    save_first_row
    empty_row   = find_empty_row
    values      = form_order_items
    value_range = form_values(values)
    range       = "#{@list_name}!#{FIRST_COLUMN}#{empty_row}:#{LAST_COLUMN}#{empty_row + values.size - 1}"
    @service.append_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
    nil
  end

  def delete_order_items_from_sheets
    ranges = find_ranges_for_order_items(@order.id)
    return if ranges.empty?

    batch_update_request = { requests: form_request(ranges) }
    @service.batch_update_spreadsheet(SPREADSHEET_ID, batch_update_request)
    nil
  end

  private

  def form_request(ranges)
    sheet_id = get_sheet_id(@list_name)
    sorted_ranges = ranges.sort_by { |range| -range[:start_index] }
    sorted_ranges.map do |range|
      { delete_dimension: { range: { sheet_id: sheet_id,
                                     dimension: 'ROWS',
                                     start_index: range[:start_index],
                                     end_index: range[:end_index] } } }
    end
  end

  def find_ranges_for_order_items(order_id)
    ranges   = []
    range    = "#{@list_name}!#{FIRST_COLUMN}2:#{FIRST_COLUMN}"
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    response.values&.each_with_index do |row, index|
      next if row[0].to_i != order_id

      start_index = index + 1 # Индексы в API начинаются с 0, но строки начинаются с 1
      end_index   = start_index + 1
      ranges << { start_index: start_index, end_index: end_index }
    end

    ranges
  end

  def save_first_row
    range = "#{@list_name}!#{FIRST_COLUMN}1:#{LAST_COLUMN}1"
    value = [['ID заказа', 'Дата оплаты', 'ID клиента', 'ФИО', 'Адрес', 'Доставка',
              'ID Товара', 'Название товара', 'Кол-во', 'Цена', 'Магазин']]
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    return if response.values == value

    value_range = form_values(value)
    @service.update_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
  end

  def form_order_items
    @order.order_items.map do |i|
      prepare_mirena_order
      product_id = prepare_mirena_product_id(i)
      order_info + [product_id, i.product.name, i.quantity, i.price.to_i, ENV.fetch('HOST', 'localhost')]
    end
  end

  def prepare_mirena_product_id(order_item)
    ENV.fetch('HOST', '').include?('mirena') ? "M_#{order_item.product.id}" : order_item.product.id
  end

  def prepare_mirena_order
    return unless ENV.fetch('HOST', '').include?('mirena')

    order_info[0] = "M_#{order_info[0]}"
    order_info[2] = "M_#{order_info[2]}"
  end

  def order_info
    @order_info ||= [@order.id,
                     @order.paid_at&.strftime('%d.%m.%Y'),
                     @order.user_id,
                     @order.user.full_name,
                     @order.user.full_address,
                     (@order.has_delivery ? @order.total_amount.to_i - @order.order_items[0].price.to_i : 0)]
  end
end
