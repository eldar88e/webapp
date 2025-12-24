class Purchase < ApplicationRecord
  include ExchangeRate

  attr_accessor :send_to_supplier

  has_many :purchase_items, dependent: :destroy
  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank
  has_many :expenses, as: :expenseable, dependent: :destroy
  accepts_nested_attributes_for :expenses, allow_destroy: true, reject_if: :all_blank
  has_many :products, through: :purchase_items

  enum :status, {
    initialized: 0,          # создан (черновик)
    sent_to_supplier: 1,     # отправлен поставщику
    shipped: 2,              # В пути
    stocked: 3,              # Оприходован
    cancelled: 4             # Отменен
  }, default: :initialized

  before_validation :set_default_currency
  before_validation :apply_send_to_supplier, if: -> { send_to_supplier == '1' }

  validates :currency, presence: true

  before_save :recalc_totals
  before_save :stamp_status_timestamps

  after_create :set_exchange_rate
  after_update :update_product_stock, if: -> { can_update_stock? }
  after_update :deduct_product_stock, if: -> { can_restock? }

  after_commit :set_exchange_rate, on: :update, if: -> { status == 'sent_to_supplier' }
  after_commit :clear_last_purchase_cache
  after_commit :send_notification, on: %i[create update], if: -> { status != 'initialized' }

  def recalc_totals
    self.subtotal = purchase_items.sum(&:line_total)
    self.total    = subtotal - shipping_total
  end

  private

  def can_restock?
    [%w[stocked cancelled], %w[stocked shipped]].include?(previous_changes['status'])
  end

  def can_update_stock?
    [%w[shipped stocked], %w[cancelled stocked]].include? previous_changes['status']
  end

  def stamp_status_timestamps
    status == 'initialized' ? self.created_at = Time.current : send("#{status}_at=", Time.current)
  end

  def set_default_currency
    self.currency ||= 'TRY'
  end

  def apply_send_to_supplier
    self.status = :sent_to_supplier
    self.sent_to_supplier_at = Time.current
  end

  def send_notification
    Purchases::ReportService.call(self)
  end

  def update_product_stock
    purchase_items.each do |item|
      item.product.update!(stock_quantity: item.product.stock_quantity + item.quantity)
    end
  end

  def deduct_product_stock
    purchase_items.each do |item|
      item.product.update!(stock_quantity: item.product.stock_quantity - item.quantity)
    end
  end

  def clear_last_purchase_cache
    Rails.cache.delete_matched('last_purchase_*')
  end
end
