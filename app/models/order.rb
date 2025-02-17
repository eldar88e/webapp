class Order < ApplicationRecord
  establish_connection :primary if ENV['ORDERS_DB_HOST'].present?
  ONE_WAIT = 3.hours

  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true

  enum :status, { initialized: 0, unpaid: 1, paid: 2, processing: 3, shipped: 4, cancelled: 5, overdue: 7, refunded: 8 }

  before_save -> { self.created_at = Time.current }, if: -> { status == 'unpaid' }
  before_save -> { self.paid_at = Time.current }, if: -> { status == 'processing' }
  before_save -> { self.shipped_at = Time.current }, if: -> { status == 'shipped' }

  before_update :apply_delivery, if: -> { status == 'unpaid' }
  before_update :remove_cart, if: -> { status_changed?(from: 'unpaid', to: 'paid') }
  before_update :deduct_stock, if: -> { status_changed?(from: 'paid', to: 'processing') }
  before_update :restock_stock, if: -> { status_changed?(from: 'processing', to: 'cancelled') }
  after_commit :notify_status_change, on: %i[create update], unless: -> { status == 'initialized' }

  def order_items_with_product
    order_items.includes(:product)
  end

  def delivery_price
    has_delivery? ? Setting.fetch_value(:delivery_price).to_i : 0
  end

  def total_price
    order_items_with_product.sum { |item| item.product.price * item.quantity } + delivery_price
  end

  def self.revenue_by_date(start_date, end_date, group_by)
    where(updated_at: start_date..end_date, status: :shipped)
      .group(group_by)
      .sum(:total_amount)
  end

  def self.count_order_with_status(start_date, end_date)
    total_orders = where(updated_at: start_date..end_date).count
    result = statuses.keys.each_with_object({}) do |status, hash|
      status_count = Order.where(status: Order.statuses[status]).where(updated_at: start_date..end_date).count
      next if status_count.zero?

      hash[status.to_sym] = status_count
    end
    [result, total_orders]
  end

  def create_order_items(cart_items)
    transaction do
      cart_items.each do |cart_item|
        quantity   = [cart_item.quantity, cart_item.product.stock_quantity].min
        order_item = order_items.find_or_initialize_by(product: cart_item.product)
        order_item.destroy! && cart_item.destroy! && next if quantity < 1

        cart_item.update(quantity: quantity)
        order_item.update!(quantity: quantity, price: cart_item.product.price)
      end
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id status total_amount updated_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def order_items_str(courier = nil)
    items = order_items_with_product.map do |i|
      "• #{i.product.name} — #{i.quantity}шт.#{" — #{i.price.to_i}₽" if courier.nil?}"
    end

    items << "• Доставка — услуга — #{delivery_price}₽" if has_delivery? && courier.nil?

    items.join(",\n")
  end

  private

  def apply_delivery
    self.has_delivery = order_items.count == 1 && order_items.first.quantity == 1
    self.total_amount = total_price
  end

  def notify_status_change
    ReportJob.perform_later(order_id: id)
  end

  def remove_cart
    user.cart.destroy
  end

  def deduct_stock
    order_items_with_product.each do |order_item|
      product = order_item.product
      if product.stock_quantity >= order_item.quantity
        product.update!(stock_quantity: product.stock_quantity - order_item.quantity)
      else
        msg = "Недостаток в остатках для продукта: #{product.name} в заказе #{id}"
        Rails.logger.error msg
        TelegramJob.perform_later(msg: msg)
        raise StandardError, msg
      end
    end
  end

  def restock_stock
    order_items_with_product.each do |order_item|
      product = order_item.product
      next if product.nil? || product.id == Setting.fetch_value(:delivery_id).to_i

      product.increment!(:stock_quantity, order_item.quantity)
      Rails.logger.info "Returned #{order_item.quantity} pcs #{product.name} to stock after order #{id} cancellation."
    end
  end
end
