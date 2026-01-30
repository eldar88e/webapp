require 'caxlsx'

class StatisticExcelService
  WORKSHEET_NAME = 'Статистика по товарам'.freeze

  def initialize(product_statistics)
    @product_statistics = product_statistics
  end

  def self.call(product_statistics)
    new(product_statistics).call
  end

  def call
    package = Axlsx::Package.new

    package.workbook.add_worksheet(name: WORKSHEET_NAME) do |sheet|
      sheet.add_row xlsx_headers
      @product_statistics[:products].each do |row|
        sheet.add_row xlsx_row(row)
      end
      add_summary(sheet)
    end

    package
  end

  private

  def add_rows(workbook, data, style)
    workbook.add_worksheet(name: @year.to_s) do |sheet|
      sheet.add_row %w[Месяц Товар Количество Сумма], style: style
      add_items(data, sheet)
    end
  end

  def xlsx_headers
    [
      'ИД', 'Название', 'Цена', 'Ср. цена', 'Закуп. цена(₺)', 'Закуп. цена',
      'Подписка', 'Избранное', 'Расходы %', 'Наценка %', 'Остаток', 'В пути',
      'Деньги в товаре', 'Чистая прибыль', 'Маржа за период %',
      'Чистая прибыль за период – расходы', 'Чистая прибыль за период',
      'Расходы ₽', 'Расходы за период', 'Потребление в сутки', 'Продажи за период',
      'Стратег. запас', 'Перебор/Дефицит', 'Дней в запасе', 'Точка заказа'
    ]
  end

  def xlsx_row(row)
    result = row.values
    result.delete_at(1)

    result
  end

  def add_summary(sheet)
    sheet.add_row []
    sheet.add_row ['', 'Деньги в товаре:', @product_statistics[:money_in_product_sum]]
    sheet.add_row ['', 'Общая чистая прибыль за период:', @product_statistics[:net_profit_sum]]
    sheet.add_row ['', 'Сумма скидок:', @product_statistics[:sum_bonus]]
  end
end
