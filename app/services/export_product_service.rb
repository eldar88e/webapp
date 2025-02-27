class ExportProductService < GoogleSheetsService
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

    if row.nil?
      empty_row = find_empty_row
      range     = "#{@list_name}!A#{empty_row}:I#{empty_row + values.size - 1}"
      @service.append_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
    else
      range = "#{@list_name}!A#{row}:D#{row}"
      @service.update_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
    end

    nil
  end

  private

  def find_row_for_product(product_id)
    range = "#{@list_name}!A2:A"
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    return nil unless response.values

    response.values.each_with_index { |row, index| return index + 2 if row[0].to_s == product_id.to_s }
    nil
  end

  def save_first_row
    range    = "#{@list_name}!A1:D1"
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
