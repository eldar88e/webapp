class CourierSalaryCalculatorService
  SPECIAL_PRODUCTS = /atominex|attex/

  class << self
    def call(range = yesterday.all_day)
      # Time.zone.now.all_year, yesterday.all_day
      orders = Order.where(status: 'shipped', shipped_at: range)
      return if orders.blank?

      order_items   = order_items(orders)
      list_purchase = build_list_purchase(order_items)
      salary        = count_salary(order_items)
      build_expense(list_purchase, salary)
      notify(list_purchase, salary)
    end

    private

    def build_list_purchase(order_items)
      order_items.map do |name, quantity|
        price = build_price(name)
        "#{name}: #{quantity} шт. x #{price}₽ = #{price_to_s(quantity * price)}"
      end
    end

    def order_items(orders)
      OrderItem
        .joins(:order, :product)
        .where(order: orders)
        .group('products.name')
        .sum(:quantity)
    end

    def build_expense(list_purchase, salary)
      data = {
        category: :salary,
        description: "Курьеру за #{yesterday.strftime('%d.%m.%Yг.')}<br>#{list_purchase.join('<br>')}",
        amount: salary,
        expense_date: Time.current
      }
      expense = Expense.find_by(expense_date: Time.current.all_day, category: :salary)
      return expense.update!(data.except(:expense_date)) if expense

      Expense.create!(data) if salary.positive?
    end

    def count_salary(order_items)
      order_items.sum { |name, quantity| quantity * build_price(name) }
    end

    def build_price(name)
      atominex_price = Setting.fetch_value(:atominex_courier_price).to_i
      other_price    = Setting.fetch_value(:products_courier_price).to_i
      name.downcase.match?(SPECIAL_PRODUCTS) ? atominex_price : other_price
    end

    def notify(list_purchase, salary)
      purchases = "📦 Состав:\n#{list_purchase.join("\n")}"
      msg = "🚚 Курьеру за #{yesterday.strftime('%d.%m.%Yг.')}:\n\n#{purchases}\n\n💰 Итого: #{price_to_s(salary)}"
      Setting.fetch_value(:admin_ids).split(',').each do |id|
        User.find_by(tg_id: id.to_i)&.messages&.create(text: msg, is_incoming: false)
      end
      notify_courier(msg)
      nil
    end

    def notify_courier(msg)
      msg = msg.sub(/🚚 Курьеру/, '💸 Зарплата')
      Setting.fetch_value(:courier_ids).split(',').each do |id|
        User.find_by(id: id.to_i)&.messages&.create(text: msg, is_incoming: false)
      end
    end

    def price_to_s(price)
      MoneyService.price_to_s(price)
    end

    def yesterday
      Time.current.yesterday
    end
  end
end
