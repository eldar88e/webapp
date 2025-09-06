class Purchase < ApplicationRecord
  has_many :purchase_items, dependent: :destroy
  has_many :products, through: :purchase_items

  enum status: {
    initialized: 0,          # создан (черновик)
    sent_to_supplier: 1,     # отправлен поставщику
    acknowledged: 2,         # поставщик подтвердил
    shipped: 3,              # отгружено
    received: 4,             # принято на склад
    stocked: 5               # оприходовано
  }, _default: :initialized

  validates :currency, presence: true
  validates :exchange_rate_to_base,
            numericality: { greater_than: 0 }

  before_save :recalc_totals


  def recalc_totals
    self.subtotal = purchase_items.sum(&:line_total)
    self.total    = subtotal - shipping_total
  end
end
