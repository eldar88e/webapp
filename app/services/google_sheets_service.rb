require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class GoogleSheetsService
  SCOPES               = ['https://www.googleapis.com/auth/spreadsheets'].freeze
  SERVICE_ACCOUNT_FILE = './key.json'.freeze
  SPREADSHEET_ID       = Setting.fetch_value(:spreadsheet_id).freeze
  LIST_NAME            = Setting.fetch_value(:google_list_orders).freeze

  def initialize(order)
    @order   = order
    sheets   = Google::Apis::SheetsV4
    @service = sheets::SheetsService.new
    google_authorize
  end

  def export_order_items_to_sheets
    save_first_row
    empty_row   = find_empty_row
    values      = form_order_items
    value_range = form_values(values)
    range       = "#{LIST_NAME}!A#{empty_row}:I#{empty_row + values.size - 1}"
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
    sheet_id = get_sheet_id(LIST_NAME)
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
    range    = "#{LIST_NAME}!A2:A"
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
    range = "#{LIST_NAME}!A1:I1"
    value = [
      ['ID заказа', 'Дата оплаты', 'ID клиента', 'ФИО', 'Адрес', 'ID Товара', 'Название товара', 'Кол-во', 'Цена']
    ]
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    return if response.values == value

    value_range = form_values(value)
    @service.update_spreadsheet_value(SPREADSHEET_ID, range, value_range, value_input_option: 'RAW')
  end

  def google_authorize
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(SERVICE_ACCOUNT_FILE),
      scope: SCOPES
    )
  end

  def form_values(values)
    Google::Apis::SheetsV4::ValueRange.new(values: values)
  end

  def form_order_items
    @order.order_items.map { |i| order_info + [i.product.id, i.product.name, i.quantity, i.price.to_i] }
  end

  def order_info
    @order_info ||= [@order.id,
                     @order.paid_at&.strftime('%H:%M %d.%m.%Yг.'),
                     @order.user_id,
                     @order.user.full_name,
                     @order.user.full_address]
  end

  def find_empty_row
    range       = "#{LIST_NAME}!A:A"
    response    = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    filled_rows = response.values ? response.values.size : 1
    filled_rows + 1
  end

  def get_sheet_id(sheet_name)
    spreadsheet = @service.get_spreadsheet(SPREADSHEET_ID)
    sheet       = spreadsheet.sheets.find { |s| s.properties.title == sheet_name }
    sheet&.properties&.sheet_id
  end
end
