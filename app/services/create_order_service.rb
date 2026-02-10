class CreateOrderService
  ORDER_STATUS_FOR_UPDATE = %i[initialized] # unpaid

  def initialize(user, bonus)
    @user  = user
    @bonus = bonus.to_i
  end

  def self.call(user, bonus)
    new(user, bonus).create_order
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
      order.destroy!
      Rails.logger.warn("Order #{order.id} is empty and was deleted.")
      { success: false, error: 'Заказ пуст, возможно товары которые вы заказали закончились на складе.' }
    end
  end

  def find_or_create_order
    order = @user.orders.find_by(status: ORDER_STATUS_FOR_UPDATE)
    return @user.orders.create(bonus: @bonus) unless order

    cart_product_ids = @cart_items.pluck(:product_id)
    order.order_items.where.not(product_id: cart_product_ids).destroy_all
    order.update!(total_amount: 0, status: :initialized, bonus: @bonus)
    order
  end
end
