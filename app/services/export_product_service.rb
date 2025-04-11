class ExportProductService < GoogleSheetsService
  LAST_COLUMN = 'D'.freeze

  def initialize(product)
    super
    @product   = product
    @list_name = Setting.fetch_value(:google_list_products).freeze
  end

  def synchronize_product
    save_first_row
    values      = form_product_items
    value_range = form_values(values)
    row         = find_row_for_product(@product.id)
    return save_row(values, value_range) if row.nil?

    range = "#{@list_name}!#{FIRST_COLUMN}#{row}:#{LAST_COLUMN}#{row}"
    @service.update_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
    nil
  end

  private

  def save_row(values, value_range)
    empty_row = find_empty_row
    range     = "#{@list_name}!#{FIRST_COLUMN}#{empty_row}:#{LAST_COLUMN}#{empty_row + values.size - 1}"
    @service.append_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
    nil
  end

  def find_row_for_product(product_id)
    range    = "#{@list_name}!#{FIRST_COLUMN}2:#{FIRST_COLUMN}"
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    return nil unless response.values

    response.values.each_with_index { |row, index| return index + 2 if row[0].to_s == product_id.to_s }
    nil
  end

  def save_first_row
    range    = "#{@list_name}!#{FIRST_COLUMN}1:#{LAST_COLUMN}1"
    value    = [['ID продукта', 'Название', 'Остатки', 'Цена']]
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    return if response.values == value

    value_range = form_values(value)
    @service.update_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
  end

  def form_product_items
    [[@product.id, @product.name, @product.stock_quantity, @product.price.to_i]]
  end
end
