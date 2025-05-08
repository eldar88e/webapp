class Order < ApplicationRecord
  belongs_to :user
  belongs_to :bank_card, optional: true
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true
  validates :bonus, numericality: { greater_than_or_equal_to: 0 }

  enum :status, { initialized: 0, unpaid: 1, paid: 2, processing: 3, shipped: 4, cancelled: 5, overdue: 7, refunded: 8 }

  before_save -> { self.created_at = Time.current }, if: -> { status == 'unpaid' }
  before_save -> { self.paid_at = Time.current }, if: -> { status == 'processing' }
  before_save -> { self.shipped_at = Time.current }, if: -> { status == 'shipped' }

  before_update :cache_status, if: -> { status_changed? }
  before_update :update_total_amount, if: -> { status == 'unpaid' || bonus_changed? }
  # before_update :apply_delivery, if: -> { status == 'unpaid' }
  before_update :assign_valid_or_random_card, if: -> { status == 'unpaid' }
  before_update :remove_cart, if: -> { status_changed?(from: 'unpaid', to: 'paid') }
  before_update :deduct_stock, if: -> { status_changed?(from: 'paid', to: 'processing') }
  before_update :export_items_google, if: -> { status_changed?(from: 'paid', to: 'processing') }
  before_update :restock_stock, if: -> { status_changed?(from: 'processing', to: 'cancelled') }
  before_update :remove_items_google, if: -> { status_changed?(from: 'processing', to: 'cancelled') }

  after_update :up_order_count, if: -> { previous_changes['status'] == %w[processing shipped] }

  after_commit :notify_status_change, on: :update, unless: -> { status == 'initialized' }
  after_commit :update_main_stock, on: :update, if: -> { ENV.fetch('HOST', '').include?('mirena') }

  def order_items_with_product
    order_items.includes(:product)
  end

  def delivery_price
    has_delivery? ? Setting.fetch_value(:delivery_price).to_i : 0
  end

  def total_price
    order_items_with_product.sum { |item| item.product.price * item.quantity } + delivery_price
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
    %w[id status total_amount created_at paid_at shipped_at]
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

  def up_order_count
    user.update(order_count: user.order_count + 1)
  end

  def cache_status
    @cache_status ||= status_was
  end

  def update_main_stock
    return unless cache_status == 'processing' && status == 'shipped'

    mirena = order_items.find_by(product_id: Setting.fetch_value(:mirena_id).to_i)
    return if mirena.blank?

    UpdateProductStockJob.perform_later(mirena.product_id, Setting.fetch_value(:main_webhook_url), mirena.quantity)
  end

  # apply_delivery
  def update_total_amount
    self.has_delivery = order_items.count == 1 && order_items.first.quantity == 1
    total_price_without_bonus = total_price
    result = bonus.zero? ? total_price_without_bonus : total_price_without_bonus - bonus
    self.total_amount = result
  end

  def assign_valid_or_random_card
    return if BankCard.cached_available_ids.any?(bank_card_id)

    self.bank_card_id = BankCard.sample_bank_card_id
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
        throw_abort(product)
      end
    end
  end

  def throw_abort(product)
    msg = "Недостаток в остатках для продукта: #{product.name} в заказе #{id}"
    Rails.logger.error msg

    # TelegramJob.perform_later(msg: msg) # TODO: не отработает т.к. транзакция + в группе "Оплата пришла" нажав
    # TODO: сообщение удалится но по факту статус останется прежним. Только в админке корректно выйдет флеш

    errors.add(:base, msg)
    throw :abort
  end

  def restock_stock
    order_items_with_product.each do |order_item|
      product = order_item.product
      product.update(stock_quantity: product.stock_quantity + order_item.quantity)
      Rails.logger.info "Returned #{order_item.quantity} pcs #{product.name} to stock after order #{id} cancellation."
    end
  end

  def export_items_google
    GoogleSheetsExporterJob.perform_later(ids: id, model: :order)
  end

  def remove_items_google
    GoogleSheetsExporterJob.perform_later(ids: id, del: true, model: :order)
  end
end
