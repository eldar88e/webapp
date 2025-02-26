class CreateOrderService
  def initialize(user)
    @user = user
  end

  def self.call(user)
    new(user).create_order
  end

  def create_order
    @cart_items = @user.cart.cart_items_with_product
    return { success: false, error: 'Ваша корзина пуста' } if @cart_items.blank?

    order = find_or_create_order
    order.create_order_items(@cart_items)
    check_order(order)
  rescue StandardError => e
    Rails.logger.error("Ошибка при создании заказа: #{e.message}")
    { success: false, error: 'Ошибка при создании заказа' }
  end

  private

  def check_order(order)
    if order.order_items.exists?
      order.update!(status: :unpaid)
      { success: true }
    else
      { success: false, error: 'Заказ пуст, возможно товары которые вы заказали закончились на складе.' }
    end
  end

  def find_or_create_order
    order = @user.orders.find_by(status: %i[unpaid initialized])
    return @user.orders.create unless order

    cart_product_ids = @cart_items.pluck(:product_id)
    order.order_items.where.not(product_id: cart_product_ids).destroy_all
    order.update!(total_amount: 0, status: :initialized)
    order
  end
end
