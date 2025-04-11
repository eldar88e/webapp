require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class GoogleSheetsService
  SCOPES               = ['https://www.googleapis.com/auth/spreadsheets'].freeze
  SERVICE_ACCOUNT_FILE = './key.json'.freeze
  SPREADSHEET_ID       = Setting.fetch_value(:spreadsheet_id).freeze
  FIRST_COLUMN         = 'A'.freeze

  def initialize(_model)
    sheets   = Google::Apis::SheetsV4
    @service = sheets::SheetsService.new
    google_authorize
  end

  private

  def form_values(values)
    Google::Apis::SheetsV4::ValueRange.new(values: values)
  end

  def find_empty_row
    range       = "#{@list_name}!#{FIRST_COLUMN}:#{FIRST_COLUMN}"
    response    = @service.get_spreadsheet_values(SPREADSHEET_ID, range)
    filled_rows = response.values ? response.values.size : 1
    filled_rows + 1
  end

  def google_authorize
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(SERVICE_ACCOUNT_FILE),
      scope: SCOPES
    )
  end

  def get_sheet_id(sheet_name)
    spreadsheet = @service.get_spreadsheet(SPREADSHEET_ID)
    sheet       = spreadsheet.sheets.find { |s| s.properties.title == sheet_name }
    sheet&.properties&.sheet_id
  end
end
