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
      order_items.map do |product_name, total_quantity|
        price = SPECIAL_PRODUCTS.include?(product_name.downcase) ? 350 : 150
        "#{product_name}: #{total_quantity} шт. x #{price}₽ = #{price_to_s(total_quantity * price)}"
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

      Expense.create!(data)
    end

    def count_salary(order_items)
      atominex_price = Setting.fetch_value(:atominex_courier_price).to_i
      other_price    = Setting.fetch_value(:products_courier_price).to_i
      order_items.sum do |name, total_quantity|
        rate = name.downcase.match?(SPECIAL_PRODUCTS) ? atominex_price : other_price
        total_quantity * rate
      end
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
