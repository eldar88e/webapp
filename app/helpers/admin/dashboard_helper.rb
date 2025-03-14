module Admin
  module DashboardHelper
    LIMIT = 200_000

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
