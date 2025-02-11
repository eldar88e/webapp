class Order < ApplicationRecord
  ONE_WAIT = 3.hours

  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true

  enum :status, { initialized: 0, unpaid: 1, paid: 2, processing: 3, shipped: 4, cancelled: 5, overdue: 7, refunded: 8 }

  before_update :remove_cart, if: -> { status_changed?(from: 'unpaid', to: 'paid') }
  before_update :deduct_stock, if: -> { status_changed?(from: 'paid', to: 'processing') }
  before_update :restock_stock, if: -> { status_changed?(from: 'processing', to: 'cancelled') }
  after_commit :check_status_change # , if: -> { saved_change_to_status? }

  def order_items_with_product
    order_items.includes(:product)
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

  def self.ransackable_attributes(_auth_object = nil)
    %w[id status total_amount updated_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def order_items_str(courier = false)
    order_items_with_product.filter_map do |i|
      next if i.product.name == 'Доставка' && courier

      resust = "• #{i.product.name} — #{i.product.name == 'Доставка' ? 'услуга' : "#{i.quantity}шт."}"
      resust += " — #{i.price.to_i}₽" unless courier
      resust
    end.join(",\n")
  end

  private

  def check_status_change
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
