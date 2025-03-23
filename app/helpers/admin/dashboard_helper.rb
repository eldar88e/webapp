module Admin
  module DashboardHelper
    LIMIT = 200_000
    SAFE_LIST_TAILWIND = {
      light_text: %w[text-blue-600 text-red-600 text-green-600 text-indigo-600 text-purple-600],
      light_bg: %w[bg-blue-600 bg-red-600 bg-green-600 bg-indigo-600 bg-purple-600],
      dark_text: %w[text-blue-800 text-red-800 text-green-800 text-indigo-800 text-purple-800],
      dark_bg: %w[bg-blue-800 bg-red-800 bg-green-800 bg-indigo-800 bg-purple-800]
    }.freeze

    def charts_config
      [
        { title: 'Статистика заказов', controller: 'orders' },
        { title: 'Продажа товаров', controller: 'sold' },
        { title: 'Повторные заказы', controller: 'repeat' }
      ]
    end

    def card_percent(balance)
      [(100 * balance.to_i / LIMIT), LIMIT].min
    end

    def random_color
      %w[blue-600 red-600 green-600 indigo-600 purple-600].sample
    end

    def average_income(sum)
      (sum / Time.current.day).round(2)
    end
  end
end
