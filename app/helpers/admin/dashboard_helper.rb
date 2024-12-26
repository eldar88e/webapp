module Admin
  module DashboardHelper
    def charts_config
      [
        { title: 'Статистика заказов', controller: 'orders' },
        { title: 'Продажа товаров', controller: 'sold' },
        { title: 'Повторные заказы', controller: 'repeat' }
      ]
    end
  end
end
