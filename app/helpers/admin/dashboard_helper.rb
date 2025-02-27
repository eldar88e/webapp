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

    def card_percent(key)
      [(100 * @totals_by_card[key].to_i / LIMIT), LIMIT].min
    end

    def random_color
      %w[blue-600 red-600 green-600 yellow-400 indigo-600 purple-600].sample
    end
  end
end
