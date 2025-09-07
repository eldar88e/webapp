class Purchase < ApplicationRecord
  attr_accessor :send_to_supplier

  has_many :purchase_items, dependent: :destroy
  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank
  has_many :products, through: :purchase_items

  enum :status, {
    initialized: 0,          # создан (черновик)
    sent_to_supplier: 1,     # отправлен поставщику
    acknowledged: 2,         # поставщик подтвердил
    shipped: 3,              # отгружено
    received: 4,             # принято на склад
    stocked: 5               # оприходовано
  }, default: :initialized

  before_validation :set_default_currency
  validates :currency, presence: true

  before_save :recalc_totals
  before_save :stamp_status_timestamps

  after_create :set_exchange_rate
  after_create :sent_to_supplier!, if: -> { send_to_supplier == '1' }
  after_update :set_exchange_rate, if: -> { status == 'sent_to_supplier' }
  after_update :send_notification, unless: -> { status == 'initialized' }
  after_update :update_product_stock, if: -> { status == 'stocked' }

  def recalc_totals
    self.subtotal = purchase_items.sum(&:line_total)
    self.total    = subtotal - shipping_total
  end

  private

  def stamp_status_timestamps
    status == 'initialized' ? self.created_at = Time.current : send("#{status}_at=", Time.current)
  end

  def set_default_currency
    self.currency ||= 'TRY'
  end

  def set_exchange_rate
    ExchangeRateSyncJob.perform_later(self.class.to_s, id)
  end

  def sent_to_supplier!
    self.status = :sent_to_supplier
    self.sent_to_supplier_at = Time.current
    save!
  end

  def send_notification
    Purchases::ReportService.call(self)
  end

  def update_product_stock
    purchase_items.each do |item|
      item.product.update!(stock_quantity: item.product.stock_quantity + item.quantity)
    end
  end
end
